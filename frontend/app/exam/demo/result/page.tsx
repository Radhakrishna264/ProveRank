'use client'
import { useState, useEffect } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'

export default function ExamResult() {
  const router = useRouter()
  const [result, setResult] = useState<any>(null)
  const [lang, setLang]     = useState<'en'|'hi'>('en')
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
    const sl = localStorage.getItem('pr_lang') as 'en'|'hi'; if(sl) setLang(sl)
    const raw = localStorage.getItem('pr_exam_result')
    if (raw) setResult(JSON.parse(raw))
    else setResult({ score:610, correct:152, wrong:18, skipped:10, total:180, timeUsed:9540 })
  }, [])

  if (!mounted || !result) return <div style={{minHeight:'100vh',background:'#000A18'}}/>

  const pct = Math.round((result.correct/result.total)*100)
  const grade = result.score >= 600 ? 'A+' : result.score >= 500 ? 'A' : result.score >= 400 ? 'B' : 'C'
  const gradeColor = result.score >= 600 ? '#00C48C' : result.score >= 500 ? '#4D9FFF' : result.score >= 400 ? '#FFA502' : '#FF4757'
  const timeUsedMin = Math.floor(result.timeUsed/60)

  return (
    <div style={{minHeight:'100vh',background:'#000A18',fontFamily:'Inter,sans-serif',color:'#E8F4FF',padding:'0 0 40px'}}>
      <style>{`
        @keyframes fadeUp{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}
        @keyframes scaleIn{from{opacity:0;transform:scale(0.85)}to{opacity:1;transform:scale(1)}}
        * { box-sizing: border-box; }
        @media(max-width:600px){
          .res-grid{grid-template-columns:repeat(2,1fr)!important;}
          .res-body{padding:16px!important;}
          .score-num{font-size:clamp(2.5rem,12vw,5rem)!important;}
          .share-row{flex-direction:column!important;}
          .share-row button{width:100%!important;}
        }
      `}</style>

      {/* Header */}
      <div style={{background:'rgba(0,4,14,0.97)',borderBottom:'1px solid rgba(77,159,255,0.15)',padding:'14px 20px',display:'flex',justifyContent:'space-between',alignItems:'center',position:'sticky',top:0,zIndex:50}}>
        <div style={{display:'flex',alignItems:'center',gap:10}}>
          <svg width={24} height={24} viewBox="0 0 64 64"><polygon points={[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return`${32+26*Math.cos(a)},${32+26*Math.sin(a)}`}).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="2"/><text x="32" y="37" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="12" fontWeight="700" fill="#4D9FFF">PR</text></svg>
          <span style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:800,color:'#4D9FFF'}}>Result</span>
        </div>
        <div style={{display:'flex',gap:8}}>
          <Link href="/dashboard/analytics" style={{padding:'7px 14px',borderRadius:10,border:'1px solid rgba(77,159,255,0.3)',background:'transparent',color:'#4D9FFF',fontSize:12,fontWeight:600,textDecoration:'none'}}>📊 {lang==='en'?'Analytics':'विश्लेषण'}</Link>
          <Link href="/dashboard" style={{padding:'7px 14px',borderRadius:10,border:'none',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',fontSize:12,fontWeight:700,textDecoration:'none'}}>🏠 {lang==='en'?'Dashboard':'डैशबोर्ड'}</Link>
        </div>
      </div>

      <div className="res-body" style={{maxWidth:700,margin:'0 auto',padding:'28px 16px',animation:'fadeUp 0.5s ease forwards'}}>

        {/* Score Hero */}
        <div style={{background:'linear-gradient(135deg,rgba(0,40,100,0.6),rgba(0,22,55,0.6))',border:'2px solid rgba(77,159,255,0.3)',borderRadius:24,padding:'32px 24px',textAlign:'center',marginBottom:20,position:'relative',overflow:'hidden',animation:'scaleIn 0.4s ease forwards'}}>
          <div style={{position:'absolute',top:-20,right:-20,fontSize:150,opacity:.04,color:'#4D9FFF',fontFamily:'monospace',pointerEvents:'none'}}>⬡</div>
          <div style={{fontSize:12,letterSpacing:'0.15em',textTransform:'uppercase',color:'#4D9FFF',fontWeight:700,marginBottom:8}}>NEET FULL MOCK TEST #13</div>
          <div className="score-num" style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(3rem,12vw,5.5rem)',fontWeight:800,background:'linear-gradient(90deg,#4D9FFF,#FFFFFF,#4D9FFF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',lineHeight:1,marginBottom:4}}>
            {result.score}
          </div>
          <div style={{fontSize:16,color:'#6B8BAF',marginBottom:16}}>/ 720</div>
          <div style={{display:'inline-flex',gap:20,flexWrap:'wrap',justifyContent:'center'}}>
            <div style={{textAlign:'center'}}>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:28,fontWeight:800,color:'#FFD700'}}>#234</div>
              <div style={{fontSize:10,color:'#6B8BAF',textTransform:'uppercase',letterSpacing:'0.08em'}}>{lang==='en'?'AIR Rank':'AIR रैंक'}</div>
            </div>
            <div style={{width:1,background:'rgba(77,159,255,0.2)'}}/>
            <div style={{textAlign:'center'}}>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:28,fontWeight:800,color:'#00C48C'}}>96.8%</div>
              <div style={{fontSize:10,color:'#6B8BAF',textTransform:'uppercase',letterSpacing:'0.08em'}}>{lang==='en'?'Percentile':'प्रतिशतक'}</div>
            </div>
            <div style={{width:1,background:'rgba(77,159,255,0.2)'}}/>
            <div style={{textAlign:'center'}}>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:28,fontWeight:800,color:gradeColor}}>{grade}</div>
              <div style={{fontSize:10,color:'#6B8BAF',textTransform:'uppercase',letterSpacing:'0.08em'}}>{lang==='en'?'Grade':'ग्रेड'}</div>
            </div>
          </div>
        </div>

        {/* Stats Grid */}
        <div className="res-grid" style={{display:'grid',gridTemplateColumns:'repeat(4,1fr)',gap:10,marginBottom:20}}>
          {[
            {label:lang==='en'?'Correct':'सही',   val:result.correct, color:'#00C48C', icon:'✓'},
            {label:lang==='en'?'Wrong':'गलत',     val:result.wrong,   color:'#FF4757', icon:'✗'},
            {label:lang==='en'?'Skipped':'छोड़े',  val:result.skipped, color:'#FFA502', icon:'—'},
            {label:lang==='en'?'Accuracy':'सटीकता',val:`${pct}%`,    color:'#4D9FFF', icon:'🎯'},
          ].map((s,i)=>(
            <div key={i} style={{background:`${s.color}10`,border:`1px solid ${s.color}33`,borderRadius:14,padding:'14px 10px',textAlign:'center'}}>
              <div style={{fontSize:20,marginBottom:4}}>{s.icon}</div>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:800,color:s.color}}>{s.val}</div>
              <div style={{fontSize:11,color:'#6B8BAF'}}>{s.label}</div>
            </div>
          ))}
        </div>

        {/* Time used */}
        <div style={{background:'rgba(0,18,36,0.8)',border:'1px solid rgba(77,159,255,0.14)',borderRadius:14,padding:'14px 18px',marginBottom:20,display:'flex',justifyContent:'space-between',alignItems:'center',flexWrap:'wrap',gap:10}}>
          <span style={{color:'#6B8BAF',fontSize:13}}>⏱ {lang==='en'?'Time Used':'समय लगा'}</span>
          <span style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:16,color:'#E8F4FF'}}>{timeUsedMin} {lang==='en'?`min (${200-Math.floor((200*60-result.timeUsed)/60)} min remaining)`:`मिनट`}</span>
        </div>

        {/* Subject breakdown */}
        <div style={{background:'rgba(0,18,36,0.8)',border:'1px solid rgba(77,159,255,0.14)',borderRadius:16,padding:'18px',marginBottom:20}}>
          <h3 style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,marginBottom:16,color:'#E8F4FF'}}>🧪 {lang==='en'?'Subject-wise Score':'विषय-वार स्कोर'}</h3>
          {[
            {sub:lang==='en'?'Physics':'भौतिकी',       score:148,max:180,color:'#4D9FFF'},
            {sub:lang==='en'?'Chemistry':'रसायन',      score:152,max:180,color:'#00C48C'},
            {sub:lang==='en'?'Botany':'वनस्पति विज्ञान',score:152,max:180,color:'#A855F7'},
            {sub:lang==='en'?'Zoology':'प्राणी विज्ञान',score:158,max:180,color:'#FF6B9D'},
          ].map((s,i)=>(
            <div key={i} style={{marginBottom:14}}>
              <div style={{display:'flex',justifyContent:'space-between',marginBottom:6}}>
                <span style={{fontWeight:600,fontSize:13,color:'#E8F4FF'}}>{s.sub}</span>
                <span style={{fontFamily:'Playfair Display,serif',fontWeight:800,fontSize:14,color:s.color}}>{s.score}<span style={{fontSize:11,color:'#5A7A9A'}}>/{s.max}</span></span>
              </div>
              <div style={{background:'rgba(77,159,255,0.08)',borderRadius:99,height:8,overflow:'hidden'}}>
                <div style={{height:'100%',width:`${(s.score/s.max)*100}%`,background:`linear-gradient(90deg,${s.color}77,${s.color})`,borderRadius:99,boxShadow:`0 0 8px ${s.color}44`}}/>
              </div>
            </div>
          ))}
        </div>

        {/* Action buttons */}
        <div className="share-row" style={{display:'flex',gap:10,flexWrap:'wrap'}}>
          <button onClick={()=>router.push('/exam/demo/attempt')} style={{flex:1,padding:'13px',borderRadius:12,border:'1.5px solid rgba(77,159,255,0.3)',background:'transparent',color:'#4D9FFF',fontWeight:700,fontSize:14,cursor:'pointer',fontFamily:'Inter,sans-serif',minWidth:120}}>
            🔄 {lang==='en'?'Reattempt':'दोबारा दें'}
          </button>
          <Link href="/dashboard/analytics" style={{flex:1,minWidth:120}}>
            <button style={{width:'100%',padding:'13px',borderRadius:12,border:'none',background:'linear-gradient(135deg,#00C48C,#007A5C)',color:'#fff',fontWeight:700,fontSize:14,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>
              📊 {lang==='en'?'Full Analysis':'विश्लेषण'}
            </button>
          </Link>
          <Link href="/dashboard" style={{flex:1,minWidth:120}}>
            <button style={{width:'100%',padding:'13px',borderRadius:12,border:'none',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',fontWeight:700,fontSize:14,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>
              🏠 {lang==='en'?'Dashboard':'डैशबोर्ड'}
            </button>
          </Link>
        </div>
      </div>
    </div>
  )
}
