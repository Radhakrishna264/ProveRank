'use client'
import { useState, useEffect } from 'react'
import DashLayout from '@/components/DashLayout'

const certs = [
  { id:1, title:'NEET Mock Excellence', subtitle:'Top 5% Performer', score:632, rank:189, date:'Feb 14, 2026', color:'#FFD700' },
  { id:2, title:'100-Day Streak', subtitle:'Consistent Learner Award', score:null, rank:null, date:'Mar 1, 2026', color:'#4D9FFF' },
  { id:3, title:'Biology Master', subtitle:'95%+ in Biology — 3 Tests', score:null, rank:null, date:'Feb 20, 2026', color:'#00C48C' },
]

export default function Certificate() {
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

  const cert = certs[selected]

  return (
    <DashLayout title={lang==='en'?'Certificates':'प्रमाण पत्र'} subtitle={lang==='en'?'Your achievements & certificates':'आपकी उपलब्धियां और प्रमाण पत्र'}>
      <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(280px,1fr))',gap:16,marginBottom:28}}>
        {certs.map((c,i)=>(
          <div key={c.id} onClick={()=>setSelected(i)} style={{background:selected===i?`rgba(77,159,255,0.1)`:v.card,border:`2px solid ${selected===i?'#4D9FFF':v.bord}`,borderRadius:16,padding:20,cursor:'pointer',transition:'all 0.3s'}}>
            <div style={{fontSize:32,marginBottom:8}}>🏆</div>
            <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:16,color:v.tm,marginBottom:4}}>{c.title}</div>
            <div style={{fontSize:12,color:c.color,fontWeight:600,marginBottom:8}}>{c.subtitle}</div>
            <div style={{fontSize:11,color:v.ts}}>{c.date}</div>
          </div>
        ))}
      </div>

      {/* Certificate Preview */}
      <div style={{background:dark?'linear-gradient(135deg,#000A18 0%,#001E3A 50%,#000A18 100%)':'linear-gradient(135deg,#EFF6FF,#DBEAFE,#EFF6FF)',border:`2px solid ${cert.color}44`,borderRadius:20,padding:48,textAlign:'center',position:'relative',overflow:'hidden',marginBottom:20}}>
        {/* Corner decorations */}
        {[[0,0],[0,'auto'],['auto',0],['auto','auto']].map(([t,r],i)=>(
          <div key={i} style={{position:'absolute',top:i<2?12:'auto',bottom:i>=2?12:'auto',left:i%2===0?12:'auto',right:i%2===1?12:'auto',width:32,height:32,border:`2px solid ${cert.color}66`,borderRadius:4,opacity:.6}}/>
        ))}
        {/* Watermark hex */}
        <div style={{position:'absolute',top:'50%',left:'50%',transform:'translate(-50%,-50%)',opacity:0.03,fontSize:300,fontFamily:'monospace',color:'#4D9FFF',pointerEvents:'none',userSelect:'none'}}>⬡</div>

        <div style={{position:'relative',zIndex:2}}>
          {/* Logo */}
          <div style={{display:'flex',justifyContent:'center',marginBottom:16}}>
            <svg width={48} height={48} viewBox="0 0 64 64">
              <polygon points={[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return`${32+27*Math.cos(a)},${32+27*Math.sin(a)}`}).join(' ')} fill="none" stroke={cert.color} strokeWidth="2"/>
              <text x="32" y="37" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="14" fontWeight="700" fill={cert.color}>PR</text>
            </svg>
          </div>
          <div style={{fontSize:11,letterSpacing:'0.2em',textTransform:'uppercase',color:cert.color,fontWeight:700,marginBottom:12}}>
            {lang==='en'?'CERTIFICATE OF ACHIEVEMENT':'उपलब्धि का प्रमाण पत्र'}
          </div>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(1.6rem,4vw,2.4rem)',fontWeight:800,color:dark?'#E8F4FF':'#0F172A',marginBottom:8}}>
            {cert.title}
          </div>
          <div style={{color:dark?'#6B8BAF':'#64748B',fontSize:14,marginBottom:20}}>
            {lang==='en'?'This certifies that':'यह प्रमाणित करता है कि'}
          </div>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(1.2rem,3vw,1.8rem)',fontWeight:700,color:cert.color,marginBottom:20,fontStyle:'italic'}}>
            Student
          </div>
          <div style={{color:dark?'#6B8BAF':'#64748B',fontSize:14,maxWidth:400,margin:'0 auto 24px'}}>
            {lang==='en'?`has earned the award for "${cert.subtitle}" on ProveRank Platform.`:`ProveRank प्लेटफॉर्म पर "${cert.subtitle}" के लिए यह पुरस्कार प्राप्त किया है।`}
          </div>
          {cert.score && (
            <div style={{display:'inline-flex',gap:32,background:`${cert.color}11`,border:`1px solid ${cert.color}33`,borderRadius:12,padding:'12px 28px',marginBottom:24}}>
              <div style={{textAlign:'center'}}><div style={{fontFamily:'Playfair Display,serif',fontSize:24,fontWeight:800,color:cert.color}}>{cert.score}</div><div style={{fontSize:10,color:dark?'#6B8BAF':'#64748B',textTransform:'uppercase',letterSpacing:'0.06em'}}>Score</div></div>
              <div style={{textAlign:'center'}}><div style={{fontFamily:'Playfair Display,serif',fontSize:24,fontWeight:800,color:cert.color}}>#{cert.rank}</div><div style={{fontSize:10,color:dark?'#6B8BAF':'#64748B',textTransform:'uppercase',letterSpacing:'0.06em'}}>AIR</div></div>
            </div>
          )}
          <div style={{display:'flex',justifyContent:'space-between',borderTop:`1px solid ${cert.color}22`,paddingTop:16,fontSize:11,color:dark?'#3A5A7A':'#94A3B8'}}>
            <span>ProveRank • praveenkumar100806@gmail.com</span>
            <span>{cert.date}</span>
          </div>
        </div>
      </div>
      <div style={{display:'flex',gap:12,flexWrap:'wrap'}}>
        <button style={{padding:'12px 28px',borderRadius:10,border:'none',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',fontWeight:700,fontSize:14,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>
          📥 {lang==='en'?'Download PDF':'PDF डाउनलोड'}
        </button>
        <button style={{padding:'12px 22px',borderRadius:10,border:`1px solid rgba(77,159,255,0.3)`,background:'transparent',color:'#4D9FFF',fontWeight:600,fontSize:14,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>
          🔗 {lang==='en'?'Share':'साझा करें'}
        </button>
      </div>
    </DashLayout>
  )
}
