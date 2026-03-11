'use client'
import { useState, useEffect } from 'react'
import DashLayout from '@/components/DashLayout'

const mock = [
  {r:1,n:'Arjun Sharma',s:692,p:99.8,acc:96.1,badge:'🥇'},
  {r:2,n:'Priya Kapoor', s:685,p:99.5,acc:94.7,badge:'🥈'},
  {r:3,n:'Rohit Verma',  s:681,p:99.2,acc:93.9,badge:'🥉'},
  {r:4,n:'Sneha Patel',  s:672,p:98.8,acc:92.2,badge:''},
  {r:5,n:'Karan Singh',  s:668,p:98.4,acc:91.6,badge:''},
  {r:6,n:'Ananya Roy',   s:661,p:97.9,acc:90.8,badge:''},
  {r:7,n:'Vikash Kumar', s:654,p:97.2,acc:90.0,badge:''},
  {r:8,n:'Divya Sharma', s:648,p:96.6,acc:89.3,badge:''},
  {r:9,n:'Rahul Gupta',  s:641,p:95.9,acc:88.5,badge:''},
  {r:10,n:'Meera Jain',  s:632,p:95.1,acc:87.7,badge:''},
]

export default function Leaderboard() {
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const [mounted, setMounted] = useState(false)
  useEffect(()=>{ setMounted(true); const sl=localStorage.getItem('pr_lang') as 'en'|'hi'; if(sl) setLang(sl) },[])
  const dark = mounted ? localStorage.getItem('pr_theme')!=='light' : true
  const v = { card: dark?'rgba(0,18,36,0.9)':'rgba(255,255,255,0.95)', bord: dark?'rgba(77,159,255,0.14)':'rgba(77,159,255,0.25)', tm: dark?'#E8F4FF':'#0F172A', ts: dark?'#6B8BAF':'#64748B' }

  return (
    <DashLayout title={lang==='en'?'Leaderboard':'लीडरबोर्ड'} subtitle={lang==='en'?'All India Rankings — Live':'अखिल भारत रैंकिंग — लाइव'}>
      {/* Top 3 Podium */}
      <div style={{display:'flex',justifyContent:'center',gap:16,alignItems:'flex-end',marginBottom:32,flexWrap:'wrap'}}>
        {[mock[1],mock[0],mock[2]].map((s,i)=>{
          const h=[80,100,70][i]; const clr=['#C0C0C0','#FFD700','#CD7F32'][i]; const pos=[2,1,3][i]
          return (
            <div key={s.r} style={{display:'flex',flexDirection:'column',alignItems:'center',gap:8}}>
              <div style={{fontSize:i===1?48:36}}>{s.badge||['🥈','🥇','🥉'][i]}</div>
              <div style={{fontWeight:700,fontSize:i===1?16:14,color:v.tm,textAlign:'center',maxWidth:100}}>{s.n}</div>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:i===1?24:18,fontWeight:800,color:clr}}>{s.s}</div>
              <div style={{width:i===1?100:80,height:h,background:`linear-gradient(180deg,${clr}33,${clr}11)`,border:`2px solid ${clr}55`,borderRadius:'8px 8px 0 0',display:'flex',alignItems:'center',justifyContent:'center'}}>
                <span style={{fontFamily:'Playfair Display,serif',fontWeight:800,fontSize:22,color:clr}}>#{pos}</span>
              </div>
            </div>
          )
        })}
      </div>

      <div style={{background:v.card,border:`1px solid ${v.bord}`,borderRadius:18,overflow:'hidden'}}>
        <div style={{padding:'16px 22px',borderBottom:`1px solid ${v.bord}`}}>
          <h2 style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:v.tm}}>
            🏆 {lang==='en'?'All India Ranking':'अखिल भारत रैंकिंग'}
          </h2>
        </div>
        <div style={{overflowX:'auto'}}>
          <table style={{width:'100%',borderCollapse:'collapse'}}>
            <thead>
              <tr>{[lang==='en'?'Rank':'रैंक',lang==='en'?'Name':'नाम',lang==='en'?'Score':'स्कोर','%ile',lang==='en'?'Accuracy':'सटीकता'].map(h=>(
                <th key={h} style={{padding:'12px 20px',textAlign:'left',fontSize:11,fontWeight:700,color:v.ts,letterSpacing:'0.06em',textTransform:'uppercase',borderBottom:`1px solid ${v.bord}`}}>{h}</th>
              ))}</tr>
            </thead>
            <tbody>
              {mock.map((s,i)=>(
                <tr key={i} onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.04)')} onMouseLeave={e=>(e.currentTarget.style.background='transparent')}>
                  <td style={{padding:'14px 20px',borderBottom:`1px solid rgba(0,45,85,0.2)`}}>
                    <span style={{fontFamily:'Playfair Display,serif',fontWeight:800,fontSize:16,color:i<3?['#FFD700','#C0C0C0','#CD7F32'][i]:'#4D9FFF'}}>{s.badge||`#${s.r}`}</span>
                  </td>
                  <td style={{padding:'14px 20px',borderBottom:`1px solid rgba(0,45,85,0.2)`,fontWeight:600,color:v.tm}}>{s.n}</td>
                  <td style={{padding:'14px 20px',borderBottom:`1px solid rgba(0,45,85,0.2)`}}><span style={{fontFamily:'Playfair Display,serif',fontWeight:800,fontSize:16,color:'#4D9FFF'}}>{s.s}</span><span style={{color:v.ts,fontSize:12}}>/720</span></td>
                  <td style={{padding:'14px 20px',borderBottom:`1px solid rgba(0,45,85,0.2)`,color:'#00C48C',fontWeight:700}}>{s.p}%</td>
                  <td style={{padding:'14px 20px',borderBottom:`1px solid rgba(0,45,85,0.2)`,color:v.ts}}>{s.acc}%</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </DashLayout>
  )
}
