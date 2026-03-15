'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

function CompareContent() {
  const { lang, darkMode:dm, token } = useShell()
  const [results,  setResults]  = useState<any[]>([])
  const [leaders,  setLeaders]  = useState<any[]>([])
  const [loading,  setLoading]  = useState(true)
  const t = (en:string, hi:string) => lang==='en' ? en : hi

  useEffect(()=>{
    if(!token) return
    const h={Authorization:`Bearer ${token}`}
    Promise.all([
      fetch(`${API}/api/results`,{headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[]),
      fetch(`${API}/api/results/leaderboard`,{headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[]),
    ]).then(([r,l])=>{setResults(Array.isArray(r)?r:[]);setLeaders(Array.isArray(l)?l:[]);setLoading(false)})
  },[token])

  const myAvg   = results.length ? Math.round(results.reduce((a,r:any)=>a+(r.score||0),0)/results.length) : 0
  const myBest  = results.length ? Math.max(...results.map((r:any)=>r.score||0)) : 0
  const topAvg  = leaders.length ? Math.round(leaders.slice(0,3).reduce((a:number,l:any)=>a+(l.score||0),0)/Math.min(3,leaders.length)) : 680
  const classAvg= leaders.length ? Math.round(leaders.reduce((a:number,l:any)=>a+(l.score||0),0)/leaders.length) : 560

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>⚖️ {t('Compare Performance','प्रदर्शन तुलना')} (S43/S80)</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('Your score vs topper vs class average','आपका स्कोर vs टॉपर vs क्लास औसत')}</div>

      <div style={{background:'linear-gradient(135deg,rgba(77,159,255,.1),rgba(0,22,40,.85))',border:'1px solid rgba(77,159,255,.2)',borderRadius:18,padding:18,marginBottom:22,display:'flex',alignItems:'center',gap:14}}>
        <span style={{fontSize:26}}>⚖️</span>
        <div style={{fontSize:13,color:C.primary,fontStyle:'italic',fontWeight:700}}>{t('"Know your competition — aim higher every day."','"अपनी प्रतिस्पर्धा को जानो — हर दिन ऊंचाई की ओर।"')}</div>
      </div>

      <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:18,marginBottom:18,backdropFilter:'blur(12px)'}}>
        <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:dm?C.text:C.textL,marginBottom:16}}>{t('Score Comparison (out of 720)','स्कोर तुलना (720 में से)')}</div>
        {loading?<div style={{textAlign:'center',padding:'30px',color:C.sub}}>⟳ Loading...</div>:(
          <div style={{display:'flex',alignItems:'flex-end',gap:10,height:140}}>
            {[[t('Your Best','आपका सर्वश्रेष्ठ'),myBest,C.primary],[t('Your Avg','आपका औसत'),myAvg,C.primary+'88'],[t('Class Avg','क्लास औसत'),classAvg,C.warn],[t('Top 3 Avg','शीर्ष 3 औसत'),topAvg,C.gold]].map(([label,val,col])=>{
              const h=Math.round(((val as number)/720)*100)
              return (
                <div key={String(label)} style={{flex:1,display:'flex',flexDirection:'column',alignItems:'center',gap:5}}>
                  <div style={{fontSize:12,fontWeight:800,color:String(col)}}>{val}</div>
                  <div style={{width:'100%',height:`${h}%`,background:`linear-gradient(180deg,${col},${col}55)`,borderRadius:'6px 6px 0 0',minHeight:4,transition:'height .8s ease'}}/>
                  <div style={{fontSize:9,color:C.sub,textAlign:'center',lineHeight:1.3}}>{label}</div>
                </div>
              )
            })}
          </div>
        )}
      </div>

      <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:18,marginBottom:18,backdropFilter:'blur(12px)'}}>
        <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:dm?C.text:C.textL,marginBottom:14}}>{t('Subject-wise Breakdown','विषय-वार विभाजन')}</div>
        {[{n:t('Physics','भौतिकी'),icon:'⚛️',mine:results[0]?.subjectScores?.physics||0,top:165,tot:180,col:'#00B4FF'},{n:t('Chemistry','रसायन'),icon:'🧪',mine:results[0]?.subjectScores?.chemistry||0,top:168,tot:180,col:'#FF6B9D'},{n:t('Biology','जीव विज्ञान'),icon:'🧬',mine:results[0]?.subjectScores?.biology||0,top:340,tot:360,col:'#00E5A0'}].map(s=>(
          <div key={s.n} style={{marginBottom:14,padding:'10px',background:'rgba(77,159,255,.04)',borderRadius:9}}>
            <div style={{display:'flex',justifyContent:'space-between',marginBottom:7,fontSize:12}}>
              <span style={{fontWeight:700,color:s.col}}>{s.icon} {s.n}</span>
              <div style={{display:'flex',gap:12}}>
                <span style={{color:C.primary}}>You: {s.mine||'—'}</span>
                <span style={{color:C.gold}}>Top: {s.top}</span>
                <span style={{color:C.sub}}>/{s.tot}</span>
              </div>
            </div>
            <div style={{position:'relative',height:11,background:'rgba(255,255,255,.06)',borderRadius:5,overflow:'hidden'}}>
              <div style={{position:'absolute',top:0,left:0,height:'100%',width:`${(s.top/s.tot)*100}%`,background:`${C.gold}44`,borderRadius:5}}/>
              {s.mine>0&&<div style={{position:'absolute',top:0,left:0,height:'100%',width:`${(s.mine/s.tot)*100}%`,background:`linear-gradient(90deg,${s.col}88,${s.col})`,borderRadius:5}}/>}
            </div>
          </div>
        ))}
      </div>

      {leaders.length>0&&(
        <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,overflow:'hidden',backdropFilter:'blur(12px)'}}>
          <div style={{padding:'13px 18px',borderBottom:`1px solid ${C.border}`,fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:dm?C.text:C.textL}}>🏆 {t('Top 5 Performers','शीर्ष 5 प्रदर्शनकर्ता')}</div>
          {leaders.slice(0,5).map((l:any,i:number)=>(
            <div key={l._id||i} style={{display:'flex',alignItems:'center',gap:10,padding:'11px 18px',borderBottom:`1px solid ${C.border}`}}>
              <span style={{width:26,height:26,borderRadius:'50%',background:i===0?`linear-gradient(135deg,${C.gold},#FF8C00)`:i===1?'linear-gradient(135deg,#C0C0C0,#808080)':i===2?'linear-gradient(135deg,#CD7F32,#8B4513)':'rgba(77,159,255,.15)',display:'flex',alignItems:'center',justifyContent:'center',fontWeight:700,fontSize:10,color:i<3?'#000':C.primary,flexShrink:0}}>{i+1}</span>
              <span style={{flex:1,fontWeight:600,fontSize:12,color:dm?C.text:C.textL}}>{l.studentName||l.name||'—'}</span>
              <span style={{fontWeight:700,fontSize:13,color:C.primary}}>{l.score||'—'}/720</span>
              {i===0&&<span>👑</span>}
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
export default function ComparePage() {
  return <StudentShell pageKey="compare"><CompareContent/></StudentShell>
}
