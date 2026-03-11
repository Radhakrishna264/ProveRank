'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import DashLayout from '@/components/DashLayout'
import { useAuth } from '@/lib/useAuth'

const API = process.env.NEXT_PUBLIC_API_URL || ''

const mockResults = [
  { id:'r1', exam:'NEET Full Mock #12', date:'Feb 28, 2026', score:610, max:720, rank:234, percentile:96.8, correct:152, incorrect:18, skipped:10, status:'Completed' },
  { id:'r2', exam:'NEET Full Mock #11', date:'Feb 21, 2026', score:587, max:720, rank:412, percentile:94.1, correct:146, incorrect:22, skipped:12, status:'Completed' },
  { id:'r3', exam:'NEET Full Mock #10', date:'Feb 14, 2026', score:632, max:720, rank:189, percentile:97.3, correct:158, incorrect:16, skipped:6,  status:'Completed' },
  { id:'r4', exam:'NEET Full Mock #9',  date:'Feb 7, 2026',  score:601, max:720, rank:290, percentile:95.6, correct:150, incorrect:20, skipped:10, status:'Completed' },
]

export default function Results() {
  const { user } = useAuth('student')
  const router   = useRouter()
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const [results, setResults] = useState(mockResults)
  const [mounted, setMounted] = useState(false)

  useEffect(()=>{
    setMounted(true)
    const sl=localStorage.getItem('pr_lang') as 'en'|'hi'; if(sl) setLang(sl)
    if (user) fetchResults()
  },[user])

  const fetchResults = async()=>{
    try {
      const r = await fetch(`${API}/api/results/my`,{headers:{Authorization:`Bearer ${user!.token}`}})
      if(r.ok){ const d=await r.json(); if(Array.isArray(d)&&d.length>0) setResults(d) }
    } catch {}
  }

  const dark = mounted ? localStorage.getItem('pr_theme')!=='light' : true
  const v = {
    card: dark ? 'rgba(0,18,36,0.9)' : 'rgba(255,255,255,0.95)',
    bord: dark ? 'rgba(77,159,255,0.14)' : 'rgba(77,159,255,0.25)',
    tm: dark ? '#E8F4FF' : '#0F172A',
    ts: dark ? '#6B8BAF' : '#64748B',
  }

  const best = results.reduce((a,b)=>a.score>b.score?a:b, results[0]||{} as any)
  const avg  = results.length ? Math.round(results.reduce((s,r)=>s+r.score,0)/results.length) : 0

  return (
    <DashLayout title={lang==='en'?'My Results':'मेरे परिणाम'} subtitle={lang==='en'?'All exam results & performance':'सभी परीक्षा परिणाम और प्रदर्शन'}>
      {/* Summary */}
      <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(180px,1fr))',gap:16,marginBottom:24}}>
        {[
          {label:lang==='en'?'Tests Taken':'दी गई परीक्षाएं',  value:results.length, color:'#4D9FFF', icon:'📝'},
          {label:lang==='en'?'Best Score':'सर्वश्रेष्ठ स्कोर', value:`${best?.score||0}/720`, color:'#FFD700', icon:'🏆'},
          {label:lang==='en'?'Average Score':'औसत स्कोर',       value:`${avg}/720`,  color:'#00C48C', icon:'📊'},
          {label:lang==='en'?'Best Rank':'सर्वश्रेष्ठ रैंक',    value:`#${best?.rank||'—'}`, color:'#A855F7', icon:'🥇'},
        ].map((s,i)=>(
          <div key={i} style={{background:v.card,border:`1px solid ${v.bord}`,borderRadius:16,padding:'18px 20px',display:'flex',gap:12,alignItems:'center'}}>
            <span style={{fontSize:28}}>{s.icon}</span>
            <div>
              <div style={{fontSize:11,color:v.ts,fontWeight:600,letterSpacing:'0.04em',textTransform:'uppercase',marginBottom:2}}>{s.label}</div>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:800,color:s.color}}>{s.value}</div>
            </div>
          </div>
        ))}
      </div>

      {/* Results List */}
      <div style={{background:v.card,border:`1px solid ${v.bord}`,borderRadius:18,overflow:'hidden'}}>
        <div style={{padding:'18px 22px',borderBottom:`1px solid ${v.bord}`,display:'flex',justifyContent:'space-between',alignItems:'center'}}>
          <h2 style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:v.tm}}>
            📋 {lang==='en'?'All Results':'सभी परिणाम'}
          </h2>
          <button style={{padding:'8px 16px',borderRadius:10,border:`1px solid rgba(77,159,255,0.3)`,background:'transparent',color:'#4D9FFF',fontSize:12,fontWeight:600,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>
            📤 {lang==='en'?'Export':'निर्यात'}
          </button>
        </div>
        {results.map((r,i)=>{
          const pct = Math.round((r.score/(r.max||720))*100)
          return (
            <div key={i} style={{padding:'18px 22px',borderBottom:i<results.length-1?`1px solid ${v.bord}`:'none',display:'flex',flexWrap:'wrap',gap:16,alignItems:'center',transition:'background 0.2s'}}
              onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.04)')}
              onMouseLeave={e=>(e.currentTarget.style.background='transparent')}>
              <div style={{flex:'1 1 200px'}}>
                <div style={{fontWeight:700,fontSize:15,color:v.tm,marginBottom:4}}>{r.exam}</div>
                <div style={{fontSize:12,color:v.ts}}>{r.date}</div>
              </div>
              <div style={{display:'flex',gap:20,flexWrap:'wrap',alignItems:'center'}}>
                <div style={{textAlign:'center'}}>
                  <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:800,color:'#4D9FFF'}}>{r.score}</div>
                  <div style={{fontSize:10,color:v.ts,textTransform:'uppercase',letterSpacing:'0.06em'}}>Score</div>
                </div>
                <div style={{textAlign:'center'}}>
                  <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:800,color:'#FFD700'}}>#{r.rank||'—'}</div>
                  <div style={{fontSize:10,color:v.ts,textTransform:'uppercase',letterSpacing:'0.06em'}}>AIR</div>
                </div>
                <div style={{textAlign:'center'}}>
                  <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:800,color:'#00C48C'}}>{r.percentile||0}%</div>
                  <div style={{fontSize:10,color:v.ts,textTransform:'uppercase',letterSpacing:'0.06em'}}>%ile</div>
                </div>
                <button onClick={()=>router.push(`/exam/demo/result?attemptId=${r.id}`)}
                  style={{padding:'9px 18px',borderRadius:10,border:'none',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',fontWeight:700,fontSize:12,cursor:'pointer',fontFamily:'Inter,sans-serif',whiteSpace:'nowrap'}}>
                  {lang==='en'?'View Details →':'विवरण →'}
                </button>
              </div>
            </div>
          )
        })}
      </div>
    </DashLayout>
  )
}
