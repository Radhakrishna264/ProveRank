'use client'
import { useState, useEffect } from 'react'
import StudentShell from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const C = { primary:'#4D9FFF', card:'rgba(0,22,40,0.80)', border:'rgba(77,159,255,0.22)', text:'#E8F4FF', sub:'#6B8FAF', success:'#00C48C', gold:'#FFD700', danger:'#FF4D4D' }

export default function LeaderboardPage() {
  return (
    <StudentShell pageKey="leaderboard">
      {({lang, darkMode:dm, user, toast, token}) => {
        const [leaders, setLeaders] = useState<any[]>([])
        const [subjectTab, setSubjectTab] = useState<'overall'|'physics'|'chemistry'|'biology'>('overall')
        const [loading, setLoading] = useState(true)
        const [myRank, setMyRank] = useState<any>(null)

        useEffect(()=>{
          if(!token) return
          const h = {Authorization:`Bearer ${token}`}
          Promise.all([
            fetch(`${API}/api/results/leaderboard${subjectTab!=='overall'?`?subject=${subjectTab}`:''}`,{headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[]),
            fetch(`${API}/api/results`,{headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[]),
          ]).then(([lb,rs])=>{
            setLeaders(Array.isArray(lb)?lb:[])
            const best = Array.isArray(rs)&&rs.length>0?rs.reduce((a:any,r:any)=>(!a||r.rank<a.rank)?r:a,null):null
            setMyRank(best)
            setLoading(false)
          })
        },[token,subjectTab])

        const medals = ['🥇','🥈','🥉']
        const rankColors = [C.gold,'#C0C0C0','#CD7F32']

        return (
          <div style={{animation:'fadeIn .4s ease'}}>
            <div style={{marginBottom:20}}>
              <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.gold},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>{lang==='en'?'Leaderboard':'लीडरबोर्ड'}</h1>
              <div style={{fontSize:13,color:C.sub}}>{lang==='en'?'All India Rankings — Live':'अखिल भारत रैंकिंग — लाइव'}</div>
            </div>

            {/* Hall of Excellence Banner */}
            <div style={{background:'linear-gradient(135deg,rgba(255,215,0,0.12),rgba(0,22,40,0.9))',border:`1px solid rgba(255,215,0,0.3)`,borderRadius:20,padding:'28px 20px',marginBottom:24,textAlign:'center',position:'relative',overflow:'hidden'}}>
              <div style={{position:'absolute',inset:0,opacity:.04}}>
                <svg width="100%" height="100%" viewBox="0 0 600 200"><text x="50%" y="65%" textAnchor="middle" fontSize="120" fontFamily="Playfair Display,serif" fontWeight="700" fill="#FFD700">🏆</text></svg>
              </div>
              <div style={{fontSize:36,marginBottom:8,animation:'float 3s ease-in-out infinite'}}>🏆</div>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:C.gold,marginBottom:4}}>{lang==='en'?'Hall of Excellence':'उत्कृष्टता की पहचान'}</div>
              <div style={{fontSize:12,color:C.sub,marginBottom:16}}>{lang==='en'?'Top students ranked by overall performance across all exams':'सभी परीक्षाओं में समग्र प्रदर्शन द्वारा शीर्ष छात्र'}</div>
              {/* Quote */}
              <div style={{display:'inline-block',background:'rgba(255,215,0,0.1)',border:'1px solid rgba(255,215,0,0.2)',borderRadius:10,padding:'10px 20px'}}>
                <div style={{fontSize:13,color:C.gold,fontStyle:'italic',fontWeight:600}}>{lang==='en'?'"Champions are made from something deep inside — a desire, a dream, a vision."':'"चैंपियन भीतर से बनते हैं — एक इच्छा, एक सपना, एक दृष्टि।"'}</div>
              </div>
            </div>

            {/* My Rank Card */}
            {myRank&&(
              <div style={{background:`linear-gradient(135deg,rgba(77,159,255,0.15),rgba(0,22,40,0.9))`,border:`2px solid rgba(77,159,255,0.4)`,borderRadius:16,padding:20,marginBottom:20,display:'flex',gap:16,alignItems:'center',flexWrap:'wrap',backdropFilter:'blur(12px)',animation:'glow 2s infinite'}}>
                <div style={{width:50,height:50,borderRadius:'50%',background:`linear-gradient(135deg,${C.primary},#0055CC)`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:20,fontWeight:900,color:'#fff',flexShrink:0}}>
                  {(user?.name||'S').charAt(0)}
                </div>
                <div style={{flex:1}}>
                  <div style={{fontSize:12,color:C.primary,fontWeight:600,marginBottom:2}}>📍 {lang==='en'?'Your Position':'आपकी स्थिति'}</div>
                  <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:dm?C.text:'#0F172A'}}>{user?.name||'You'}</div>
                </div>
                <div style={{display:'flex',gap:14}}>
                  {[[`#${myRank.rank||'—'}`,lang==='en'?'AIR':'रैंक',C.gold],[`${myRank.score}`,lang==='en'?'Score':'स्कोर',C.primary],[`${myRank.percentile||'—'}%`,lang==='en'?'ile':'ile',C.success]].map(([v,l,c])=>(
                    <div key={String(l)} style={{textAlign:'center'}}>
                      <div style={{fontWeight:800,fontSize:18,color:String(c)}}>{v}</div>
                      <div style={{fontSize:9,color:C.sub}}>{l}</div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Subject Tabs */}
            <div style={{display:'flex',gap:8,marginBottom:20,flexWrap:'wrap'}}>
              {[['overall',lang==='en'?'Overall':'समग्र','🏆'],['physics',lang==='en'?'Physics':'भौतिकी','⚛️'],['chemistry',lang==='en'?'Chemistry':'रसायन','🧪'],['biology',lang==='en'?'Biology':'जीव विज्ञान','🧬']].map(([id,name,icon])=>(
                <button key={id} onClick={()=>setSubjectTab(id as any)} style={{padding:'9px 16px',borderRadius:10,border:`1px solid ${subjectTab===id?C.primary:C.border}`,background:subjectTab===id?`${C.primary}22`:C.card,color:subjectTab===id?C.primary:C.sub,cursor:'pointer',fontWeight:subjectTab===id?700:400,fontSize:12,fontFamily:'Inter,sans-serif'}}>
                  {icon} {name}
                </button>
              ))}
            </div>

            {/* Top 3 Podium */}
            {!loading&&leaders.length>=3&&(
              <div style={{display:'flex',justifyContent:'center',alignItems:'flex-end',gap:10,marginBottom:24,padding:'20px 0'}}>
                {[leaders[1],leaders[0],leaders[2]].map((l,i)=>{
                  const pos = i===0?2:i===1?1:3
                  const h = pos===1?130:pos===2?100:85
                  const col = pos===1?C.gold:pos===2?'#C0C0C0':'#CD7F32'
                  return (
                    <div key={l?._id||i} style={{display:'flex',flexDirection:'column',alignItems:'center',gap:6,flex:pos===1?1.2:1}}>
                      <div style={{fontSize:pos===1?28:22}}>{medals[pos-1]}</div>
                      <div style={{width:48,height:48,borderRadius:'50%',background:`linear-gradient(135deg,${col},${col}88)`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:18,fontWeight:700,color:'#000',border:`3px solid ${col}`,boxShadow:`0 0 16px ${col}66`}}>
                        {(l?.studentName||l?.name||'?').charAt(0)}
                      </div>
                      <div style={{fontSize:12,fontWeight:700,color:col,textAlign:'center'}}>{l?.studentName||l?.name||'—'}</div>
                      <div style={{fontSize:11,color:C.sub}}>{l?.score||'—'}/720</div>
                      <div style={{width:'80%',height:h,background:`linear-gradient(180deg,${col}44,${col}22)`,borderRadius:'8px 8px 0 0',border:`1px solid ${col}44`,display:'flex',alignItems:'flex-start',justifyContent:'center',paddingTop:8}}>
                        <span style={{fontWeight:900,fontSize:20,color:col}}>#{pos}</span>
                      </div>
                    </div>
                  )
                })}
              </div>
            )}

            {/* Full Leaderboard */}
            <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,overflow:'hidden',backdropFilter:'blur(12px)'}}>
              <div style={{padding:'14px 20px',borderBottom:`1px solid ${C.border}`,display:'flex',justifyContent:'space-between',alignItems:'center'}}>
                <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:dm?C.text:'#0F172A'}}>🏅 {lang==='en'?'All India Ranking':'अखिल भारत रैंकिंग'}</div>
                <span style={{fontSize:10,color:C.success,fontWeight:600}}>🟢 {lang==='en'?'Live':'लाइव'}</span>
              </div>
              <div style={{display:'grid',gridTemplateColumns:'60px 1fr 100px 80px 80px',padding:'10px 20px',background:'rgba(77,159,255,0.05)',fontSize:10,color:C.primary,fontWeight:700,textTransform:'uppercase',letterSpacing:.5}}>
                <span>RANK</span><span>NAME</span><span>SCORE</span><span>%ILE</span><span>ACC%</span>
              </div>
              {loading?<div style={{textAlign:'center',padding:'40px',color:C.sub}}>⟳ Loading...</div>:
                leaders.length===0?<div style={{textAlign:'center',padding:'40px',color:C.sub,fontSize:12}}>{lang==='en'?'Leaderboard will populate after exams':'परीक्षाओं के बाद लीडरबोर्ड भरेगा'}</div>:
                leaders.slice(0,20).map((l:any,i:number)=>(
                  <div key={l._id||i} style={{display:'grid',gridTemplateColumns:'60px 1fr 100px 80px 80px',padding:'12px 20px',borderBottom:`1px solid ${C.border}`,borderLeft:i<3?`3px solid ${rankColors[i]}`:'3px solid transparent',transition:'background .15s',alignItems:'center'}}>
                    <span style={{fontWeight:900,fontSize:14,color:i<3?rankColors[i]:C.sub}}>{i<3?medals[i]:`#${i+1}`}</span>
                    <div>
                      <div style={{fontWeight:600,fontSize:13,color:dm?C.text:'#0F172A'}}>{l.studentName||l.name||'—'}</div>
                    </div>
                    <span style={{fontWeight:700,color:C.primary}}>{l.score||'—'}/720</span>
                    <span style={{color:C.success,fontWeight:600}}>{l.percentile||'—'}%</span>
                    <span style={{color:C.sub,fontSize:11}}>{l.accuracy||'—'}%</span>
                  </div>
                ))
              }
            </div>
          </div>
        )
      }}
    </StudentShell>
  )
}
