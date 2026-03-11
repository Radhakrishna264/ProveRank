'use client'
import { useState, useEffect } from 'react'
import DashLayout from '@/components/DashLayout'

const mockSubject = [
  { name:'Physics',   en:'Physics',   hi:'भौतिकी',      score:148, max:180, color:'#4D9FFF', correct:37, incorrect:12, skipped:6 },
  { name:'Chemistry', en:'Chemistry', hi:'रसायन विज्ञान',score:152, max:180, color:'#00C48C', correct:38, incorrect:8,  skipped:9 },
  { name:'Biology',   en:'Biology',   hi:'जीव विज्ञान',  score:310, max:360, color:'#A855F7', correct:77, incorrect:8,  skipped:5 },
]
const mockTests = [
  { name:'NEET Mock #12', score:610, rank:234, percentile:96.8, date:'Feb 28' },
  { name:'NEET Mock #11', score:587, rank:412, percentile:94.1, date:'Feb 21' },
  { name:'NEET Mock #10', score:632, rank:189, percentile:97.3, date:'Feb 14' },
  { name:'NEET Mock #9',  score:601, rank:290, percentile:95.6, date:'Feb 7'  },
  { name:'NEET Mock #8',  score:558, rank:510, percentile:91.8, date:'Jan 31' },
]
const weakChapters = [
  { sub:'Chemistry', chapter:'Inorganic Chemistry', acc:52, hi:'अकार्बनिक रसायन' },
  { sub:'Physics',   chapter:'Thermodynamics',      acc:58, hi:'ऊष्मागतिकी' },
  { sub:'Biology',   chapter:'Plant Physiology',    acc:63, hi:'पादप कार्यिकी' },
  { sub:'Physics',   chapter:'Modern Physics',      acc:66, hi:'आधुनिक भौतिकी' },
]
const strongChapters = [
  { sub:'Biology',  chapter:'Genetics & Evolution',    acc:94, hi:'आनुवंशिकी और विकास' },
  { sub:'Chemistry',chapter:'Organic Chemistry',       acc:89, hi:'कार्बनिक रसायन' },
  { sub:'Biology',  chapter:'Human Physiology',        acc:87, hi:'मानव कार्यिकी' },
  { sub:'Physics',  chapter:'Optics',                 acc:84, hi:'प्रकाशिकी' },
]

export default function Analytics() {
  const [lang, setLang] = useState<'en'|'hi'>('en')
  useEffect(()=>{ const sl=localStorage.getItem('pr_lang') as 'en'|'hi'; if(sl) setLang(sl) },[])
  const dark = typeof window!=='undefined' ? localStorage.getItem('pr_theme')!=='light' : true

  const v = {
    card: dark ? 'rgba(0,18,36,0.9)' : 'rgba(255,255,255,0.95)',
    bord: dark ? 'rgba(77,159,255,0.14)' : 'rgba(77,159,255,0.25)',
    tm: dark ? '#E8F4FF' : '#0F172A',
    ts: dark ? '#6B8BAF' : '#64748B',
  }

  return (
    <DashLayout title={lang==='en'?'Analytics':'विश्लेषण'} subtitle={lang==='en'?'Deep performance insights':'गहन प्रदर्शन विश्लेषण'}>
      <style>{`.pr-bar-wrap{background:rgba(77,159,255,0.08);border-radius:99px;height:10px;overflow:hidden;}.pr-bar{height:100%;border-radius:99px;transition:width 1.2s ease;}`}</style>

      {/* Score Trend */}
      <div style={{background:v.card,border:`1px solid ${v.bord}`,borderRadius:18,padding:24,marginBottom:20}}>
        <h2 style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,marginBottom:20,color:v.tm}}>
          📈 {lang==='en'?'Score Trend (Last 5 Tests)':'स्कोर ट्रेंड (अंतिम 5 परीक्षाएं)'}
        </h2>
        <div style={{display:'flex',alignItems:'flex-end',gap:12,height:120,padding:'0 8px'}}>
          {mockTests.slice().reverse().map((t,i)=>{
            const h = Math.round((t.score/720)*100)
            return (
              <div key={i} style={{flex:1,display:'flex',flexDirection:'column',alignItems:'center',gap:6}}>
                <div style={{fontSize:11,color:'#4D9FFF',fontWeight:700}}>{t.score}</div>
                <div style={{width:'100%',background:'linear-gradient(180deg,#4D9FFF,#0055CC)',borderRadius:'6px 6px 0 0',height:`${h}%`,transition:'height 1s ease',boxShadow:'0 4px 15px rgba(77,159,255,0.25)'}}/>
                <div style={{fontSize:10,color:v.ts,textAlign:'center'}}>{t.date}</div>
              </div>
            )
          })}
        </div>
      </div>

      {/* Subject Performance */}
      <div style={{background:v.card,border:`1px solid ${v.bord}`,borderRadius:18,padding:24,marginBottom:20}}>
        <h2 style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,marginBottom:20,color:v.tm}}>
          🧪 {lang==='en'?'Subject-wise Performance':'विषय-वार प्रदर्शन'}
        </h2>
        {mockSubject.map(s=>(
          <div key={s.name} style={{marginBottom:20}}>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:8}}>
              <div>
                <span style={{fontWeight:700,fontSize:15,color:v.tm}}>{lang==='en'?s.en:s.hi}</span>
                <span style={{fontSize:12,color:v.ts,marginLeft:8}}>{s.correct}✓  {s.incorrect}✗  {s.skipped}—</span>
              </div>
              <span style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:800,color:s.color}}>{s.score}<span style={{fontSize:13,color:v.ts}}>/{s.max}</span></span>
            </div>
            <div className="pr-bar-wrap">
              <div className="pr-bar" style={{width:`${(s.score/s.max)*100}%`,background:`linear-gradient(90deg,${s.color},${s.color}88)`}}/>
            </div>
          </div>
        ))}
      </div>

      {/* Weak vs Strong */}
      <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(300px,1fr))',gap:20,marginBottom:20}}>
        <div style={{background:'rgba(255,71,87,0.05)',border:'1px solid rgba(255,71,87,0.2)',borderRadius:18,padding:24}}>
          <h3 style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:'#FF4757',marginBottom:16}}>
            ⚠️ {lang==='en'?'Weak Chapters':'कमजोर अध्याय'}
          </h3>
          {weakChapters.map((c,i)=>(
            <div key={i} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'10px 14px',background:'rgba(255,71,87,0.06)',borderRadius:10,marginBottom:8}}>
              <div>
                <div style={{fontWeight:600,fontSize:13,color:v.tm}}>{lang==='en'?c.chapter:c.hi}</div>
                <div style={{fontSize:11,color:'#FF6B7A'}}>{c.sub}</div>
              </div>
              <div style={{textAlign:'right'}}>
                <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:800,color:'#FF4757'}}>{c.acc}%</div>
                <button style={{fontSize:10,color:'#4D9FFF',background:'none',border:'none',cursor:'pointer',fontFamily:'Inter,sans-serif',fontWeight:600}}>
                  {lang==='en'?'Revise →':'दोहराएं →'}
                </button>
              </div>
            </div>
          ))}
        </div>
        <div style={{background:'rgba(0,196,140,0.05)',border:'1px solid rgba(0,196,140,0.2)',borderRadius:18,padding:24}}>
          <h3 style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:'#00C48C',marginBottom:16}}>
            💪 {lang==='en'?'Strong Chapters':'मजबूत अध्याय'}
          </h3>
          {strongChapters.map((c,i)=>(
            <div key={i} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'10px 14px',background:'rgba(0,196,140,0.06)',borderRadius:10,marginBottom:8}}>
              <div>
                <div style={{fontWeight:600,fontSize:13,color:v.tm}}>{lang==='en'?c.chapter:c.hi}</div>
                <div style={{fontSize:11,color:'#00C48C'}}>{c.sub}</div>
              </div>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:800,color:'#00C48C'}}>{c.acc}%</div>
            </div>
          ))}
        </div>
      </div>

      {/* Test History Table */}
      <div style={{background:v.card,border:`1px solid ${v.bord}`,borderRadius:18,padding:24}}>
        <h2 style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,marginBottom:20,color:v.tm}}>
          📋 {lang==='en'?'Test History':'परीक्षा इतिहास'}
        </h2>
        <div style={{overflowX:'auto'}}>
          <table style={{width:'100%',borderCollapse:'collapse'}}>
            <thead>
              <tr>
                {[lang==='en'?'Test':'परीक्षा',lang==='en'?'Score':'स्कोर',lang==='en'?'Rank':'रैंक','%ile',lang==='en'?'Date':'तिथि'].map(h=>(
                  <th key={h} style={{padding:'10px 16px',textAlign:'left',fontSize:11,fontWeight:700,color:v.ts,letterSpacing:'0.06em',textTransform:'uppercase',borderBottom:`1px solid ${v.bord}`}}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {mockTests.map((t,i)=>(
                <tr key={i} onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.04)')} onMouseLeave={e=>(e.currentTarget.style.background='transparent')}>
                  <td style={{padding:'12px 16px',fontWeight:600,color:v.tm,borderBottom:`1px solid rgba(0,45,85,0.2)`}}>{t.name}</td>
                  <td style={{padding:'12px 16px',borderBottom:`1px solid rgba(0,45,85,0.2)`}}><span style={{fontFamily:'Playfair Display,serif',fontWeight:800,color:'#4D9FFF',fontSize:16}}>{t.score}</span><span style={{color:v.ts,fontSize:12}}>/720</span></td>
                  <td style={{padding:'12px 16px',borderBottom:`1px solid rgba(0,45,85,0.2)`}}><span style={{background:'rgba(77,159,255,0.12)',color:'#4D9FFF',padding:'3px 10px',borderRadius:99,fontSize:12,fontWeight:700}}>#{t.rank}</span></td>
                  <td style={{padding:'12px 16px',borderBottom:`1px solid rgba(0,45,85,0.2)`}}><span style={{color:'#00C48C',fontWeight:700}}>{t.percentile}%</span></td>
                  <td style={{padding:'12px 16px',color:v.ts,fontSize:13,borderBottom:`1px solid rgba(0,45,85,0.2)`}}>{t.date}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </DashLayout>
  )
}
