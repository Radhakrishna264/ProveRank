'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

function LeaderboardContent() {
  const {lang,darkMode:dm,user,token}=useShell()
  const [leaders,setLeaders]=useState<any[]>([])
  const [tab,    setTab]    =useState('overall')
  const [loading,setLoading]=useState(true)
  const [myResult,setMyResult]=useState<any>(null)
  const t=(en:string,hi:string)=>lang==='en'?en:hi

  useEffect(()=>{
    if(!token) return
    const h={Authorization:`Bearer ${token}`}
    Promise.all([
      fetch(`${API}/api/results/leaderboard${tab!=='overall'?`?subject=${tab}`:''}`,{headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[]),
      fetch(`${API}/api/results`,{headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[]),
    ]).then(([lb,rs])=>{
      setLeaders(Array.isArray(lb)?lb:[])
      const best=Array.isArray(rs)&&rs.length?rs.reduce((a:any,r:any)=>(!a||r.rank<a.rank)?r:a,null):null
      setMyResult(best); setLoading(false)
    })
  },[token,tab])

  const medals=['🥇','🥈','🥉']
  const rc=[C.gold,'#C0C0C0','#CD7F32']

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.gold},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>🏆 {t('Leaderboard','लीडरबोर्ड')}</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('All India Rankings — Live | Subject-wise tabs (M10)','अखिल भारत रैंकिंग — लाइव | विषय-वार टैब')}</div>

      {/* Hall of Excellence Banner */}
      <div style={{background:'linear-gradient(135deg,rgba(255,215,0,.12),rgba(0,22,40,.92))',border:'1px solid rgba(255,215,0,.28)',borderRadius:20,padding:'28px 20px',marginBottom:22,textAlign:'center',position:'relative',overflow:'hidden',boxShadow:'0 4px 24px rgba(0,0,0,.2)'}}>
        <div style={{position:'absolute',inset:0,opacity:.03}}><svg width="100%" height="100%" viewBox="0 0 600 180"><text x="50%" y="65%" textAnchor="middle" fontSize="120" fontFamily="Playfair Display,serif" fontWeight="700" fill="#FFD700">🏆</text></svg></div>
        <div style={{fontSize:38,marginBottom:10,animation:'bounce 2s ease-in-out infinite'}}>🏆</div>
        <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:C.gold,marginBottom:4,textShadow:`0 0 20px ${C.gold}44`}}>{t('Hall of Excellence','उत्कृष्टता की पहचान')}</div>
        <div style={{fontSize:12,color:C.sub,marginBottom:12}}>{t('Top students ranked by overall NEET performance','समग्र NEET प्रदर्शन द्वारा शीर्ष छात्र')}</div>
        <div style={{display:'inline-block',background:'rgba(255,215,0,.1)',border:'1px solid rgba(255,215,0,.22)',borderRadius:10,padding:'8px 18px'}}>
          <div style={{fontSize:13,color:C.gold,fontStyle:'italic',fontWeight:600}}>{t('"Champions are made from something deep inside — a desire, a dream, a vision."','"चैंपियन भीतर से बनते हैं — एक इच्छा, एक सपना, एक दृष्टि।"')}</div>
        </div>
      </div>

      {/* My Rank card */}
      {myResult&&(
        <div style={{background:`linear-gradient(135deg,rgba(77,159,255,.16),rgba(0,22,40,.92))`,border:`2px solid rgba(77,159,255,.4)`,borderRadius:16,padding:18,marginBottom:18,display:'flex',gap:14,alignItems:'center',flexWrap:'wrap',backdropFilter:'blur(14px)',animation:'glow 2s infinite',boxShadow:'0 4px 20px rgba(77,159,255,.15)'}}>
          <div style={{width:48,height:48,borderRadius:'50%',background:`linear-gradient(135deg,${C.primary},#0055CC)`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:20,fontWeight:900,color:'#fff',flexShrink:0}}>{(user?.name||'S').charAt(0)}</div>
          <div style={{flex:1}}>
            <div style={{fontSize:11,color:C.primary,fontWeight:600,marginBottom:2}}>📍 {t('Your Current Position','आपकी वर्तमान स्थिति')}</div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:C.text}}>{user?.name||t('You','आप')}</div>
          </div>
          <div style={{display:'flex',gap:14}}>
            {[[`#${myResult.rank||'—'}`,t('AIR','रैंक'),C.gold],[`${myResult.score}`,t('Score','स्कोर'),C.primary],[`${myResult.percentile||'—'}%`,t('ile','ile'),C.success]].map(([v,l,c])=>(
              <div key={String(l)} style={{textAlign:'center'}}>
                <div style={{fontWeight:800,fontSize:18,color:String(c),textShadow:`0 0 10px ${c}44`}}>{v}</div>
                <div style={{fontSize:9,color:C.sub}}>{l}</div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Subject Tabs (M10) */}
      <div style={{display:'flex',gap:8,marginBottom:18,flexWrap:'wrap'}}>
        {[['overall',t('Overall','समग्र'),'🏆'],['Physics',t('Physics','भौतिकी'),'⚛️'],['Chemistry',t('Chemistry','रसायन'),'🧪'],['Biology',t('Biology','जीव विज्ञान'),'🧬']].map(([id,name,icon])=>(
          <button key={id} onClick={()=>setTab(id)} style={{padding:'9px 16px',borderRadius:10,border:`1px solid ${tab===id?C.primary:C.border}`,background:tab===id?`${C.primary}22`:C.card,color:tab===id?C.primary:C.sub,cursor:'pointer',fontWeight:tab===id?700:400,fontSize:12,fontFamily:'Inter,sans-serif',transition:'all .2s'}}>{icon} {name}</button>
        ))}
      </div>

      {/* Podium */}
      {!loading&&leaders.length>=3&&(
        <div style={{display:'flex',justifyContent:'center',alignItems:'flex-end',gap:12,marginBottom:24,padding:'16px 0'}}>
          {[leaders[1],leaders[0],leaders[2]].map((l:any,i:number)=>{
            const pos=i===0?2:i===1?1:3
            const h=pos===1?130:pos===2?95:80
            const col=rc[pos-1]
            return (
              <div key={l?._id||i} style={{display:'flex',flexDirection:'column',alignItems:'center',gap:6,flex:pos===1?1.2:1}}>
                <div style={{fontSize:pos===1?28:22,animation:pos===1?'bounce 2s infinite':undefined}}>{medals[pos-1]}</div>
                <div style={{width:48,height:48,borderRadius:'50%',background:`linear-gradient(135deg,${col},${col}88)`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:18,fontWeight:700,color:'#000',border:`3px solid ${col}`,boxShadow:`0 0 18px ${col}55`}}>
                  {(l?.studentName||l?.name||'?').charAt(0)}
                </div>
                <div style={{fontSize:11,fontWeight:700,color:col,textAlign:'center',maxWidth:70,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap',textShadow:`0 0 8px ${col}44`}}>{l?.studentName||l?.name||'—'}</div>
                <div style={{fontSize:10,color:C.sub}}>{l?.score||'—'}/720</div>
                <div style={{width:'85%',height:h,background:`linear-gradient(180deg,${col}44,${col}22)`,borderRadius:'8px 8px 0 0',border:`1px solid ${col}44`,display:'flex',alignItems:'flex-start',justifyContent:'center',paddingTop:8}}>
                  <span style={{fontWeight:900,fontSize:20,color:col,textShadow:`0 0 8px ${col}44`}}>#{pos}</span>
                </div>
              </div>
            )
          })}
        </div>
      )}

      {/* Full table */}
      <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,overflow:'hidden',backdropFilter:'blur(14px)',boxShadow:'0 2px 16px rgba(0,0,0,.15)'}}>
        <div style={{padding:'13px 20px',borderBottom:`1px solid ${C.border}`,display:'flex',justifyContent:'space-between',alignItems:'center'}}>
          <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:dm?C.text:C.textL}}>🏅 {t('All India Ranking','अखिल भारत रैंकिंग')}</div>
          <span style={{fontSize:10,color:C.success,fontWeight:600}}>🟢 {t('Live','लाइव')}</span>
        </div>
        <div style={{display:'grid',gridTemplateColumns:'52px 1fr 90px 70px 70px',padding:'9px 18px',background:'rgba(77,159,255,.05)',fontSize:9,color:C.primary,fontWeight:700,textTransform:'uppercase',letterSpacing:.5}}>
          <span>RANK</span><span>NAME</span><span>SCORE</span><span>%ILE</span><span>ACC%</span>
        </div>
        {loading?<div style={{textAlign:'center',padding:'30px',color:C.sub,animation:'pulse 1.5s infinite'}}>⟳ Loading...</div>:
          leaders.length===0?<div style={{textAlign:'center',padding:'40px',color:C.sub,fontSize:12}}>{t('Leaderboard will populate after exams are taken','परीक्षाएं देने के बाद लीडरबोर्ड भरेगा')}</div>:
          leaders.slice(0,25).map((l:any,i:number)=>(
            <div key={l._id||i} style={{display:'grid',gridTemplateColumns:'52px 1fr 90px 70px 70px',padding:'11px 18px',borderBottom:`1px solid ${C.border}`,borderLeft:i<3?`3px solid ${rc[i]}`:'3px solid transparent',alignItems:'center',transition:'background .15s'}}>
              <span style={{fontWeight:900,fontSize:13,color:i<3?rc[i]:C.sub}}>{i<3?medals[i]:`#${i+1}`}</span>
              <span style={{fontWeight:600,fontSize:12,color:dm?C.text:C.textL,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{l.studentName||l.name||'—'}</span>
              <span style={{fontWeight:700,color:C.primary,fontSize:12}}>{l.score||'—'}/720</span>
              <span style={{color:C.success,fontWeight:600,fontSize:11}}>{l.percentile||'—'}%</span>
              <span style={{color:C.sub,fontSize:11}}>{l.accuracy||'—'}%</span>
            </div>
          ))
        }
      </div>
    </div>
  )
}

export default function LeaderboardPage() {
  return <StudentShell pageKey="leaderboard"><LeaderboardContent/></StudentShell>
}
