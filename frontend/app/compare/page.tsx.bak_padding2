'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
function CompareContent() {
  const {lang,darkMode:dm,token}=useShell()
  const [results,setResults]=useState<any[]>([])
  const [leaders,setLeaders]=useState<any[]>([])
  const [loading,setLoading]=useState(true)
  const t=(en:string,hi:string)=>lang==='en'?en:hi
  useEffect(()=>{
    if(!token) return
    const h={Authorization:`Bearer ${token}`}
    Promise.all([
      fetch(`${API}/api/results`,{headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[]),
      fetch(`${API}/api/results/leaderboard`,{headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[]),
    ]).then(([r,l])=>{setResults(Array.isArray(r)?r:[]);setLeaders(Array.isArray(l)?l:[]);setLoading(false)})
  },[token])
  const myBest=results.length?Math.max(...results.map((r:any)=>r.score||0)):0
  const myAvg=results.length?Math.round(results.reduce((a,r:any)=>a+(r.score||0),0)/results.length):0
  const topAvg=leaders.length?Math.round(leaders.slice(0,3).reduce((a:number,l:any)=>a+(l.score||0),0)/Math.min(3,leaders.length)):0
  const classAvg=leaders.length?Math.round(leaders.reduce((a:number,l:any)=>a+(l.score||0),0)/leaders.length):0
  const bars=[[t('Your Best','आपका सर्वश्रेष्ठ'),myBest,C.primary],[t('Your Avg','आपका औसत'),myAvg,C.primary+'88'],[t('Class Avg','क्लास औसत'),classAvg,C.warn],[t('Top 3 Avg','शीर्ष 3'),topAvg,C.gold]]
  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>⚖️ {t('Compare Performance','प्रदर्शन तुलना')} (S43/S80)</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('Your score vs topper vs class average — subject wise breakdown','आपका स्कोर vs टॉपर vs क्लास औसत')}</div>
      <div style={{background:'linear-gradient(135deg,rgba(77,159,255,.1),rgba(0,22,40,.88))',border:'1px solid rgba(77,159,255,.2)',borderRadius:18,padding:18,marginBottom:22,display:'flex',alignItems:'center',gap:14}}>
        <svg width="65" height="65" viewBox="0 0 65 65" fill="none" style={{animation:'float 4s ease-in-out infinite',flexShrink:0}}>
          <rect x="5" y="40" width="15" height="20" rx="2" fill="#4D9FFF" opacity=".8"/>
          <rect x="25" y="20" width="15" height="40" rx="2" fill="#FFD700" opacity=".9"/>
          <rect x="45" y="30" width="15" height="30" rx="2" fill="#00C48C" opacity=".8"/>
          <path d="M5 60h55" stroke="#4D9FFF" strokeWidth=".8"/>
          <circle cx="12.5" cy="38" r="3" fill="#4D9FFF"/>
          <circle cx="32.5" cy="18" r="3" fill="#FFD700"/>
          <circle cx="52.5" cy="28" r="3" fill="#00C48C"/>
        </svg>
        <div style={{flex:1}}>
          <div style={{fontSize:13,color:C.primary,fontStyle:'italic',fontWeight:700,marginBottom:3}}>{t('"Know your competition — aim higher every day."','"अपनी प्रतिस्पर्धा को जानो — हर दिन ऊंचाई की ओर।"')}</div>
          <div style={{fontSize:11,color:C.sub}}>{results.length?t(`Based on ${results.length} exam(s)`,`${results.length} परीक्षा के आधार पर`):t('Give exams to see comparisons','तुलना देखने के लिए परीक्षाएं दें')}</div>
        </div>
      </div>
      {!results.length&&!loading?(
        <div style={{textAlign:'center',padding:'60px 20px',background:dm?C.card:C.cardL,borderRadius:20,border:`1px solid ${C.border}`,backdropFilter:'blur(14px)'}}>
          <div style={{fontSize:40,marginBottom:12}}>⚖️</div>
          <div style={{fontWeight:700,fontSize:15,color:dm?C.text:C.textL,marginBottom:6}}>{t('No comparison data yet!','अभी तुलना डेटा नहीं!')}</div>
          <div style={{fontSize:12,color:C.sub,marginBottom:16}}>{t('Give your first exam to compare your performance with toppers and class average.','पहला परीक्षा दें और अपना प्रदर्शन टॉपर्स से तुलना करें।')}</div>
          <a href="/my-exams" className="btn-p" style={{textDecoration:'none',display:'inline-block'}}>{t('📝 Give First Exam →','📝 पहला परीक्षा दें →')}</a>
        </div>
      ):(
        <>
          <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:18,marginBottom:18,backdropFilter:'blur(14px)'}}>
            <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:dm?C.text:C.textL,marginBottom:16}}>{t('Score Comparison (out of 720)','स्कोर तुलना (720 में से)')}</div>
            <div style={{display:'flex',alignItems:'flex-end',gap:10,height:140}}>
              {bars.map(([label,val,col])=>{
                const h=Math.round(((val as number)/720)*100)
                return (
                  <div key={String(label)} style={{flex:1,display:'flex',flexDirection:'column',alignItems:'center',gap:5}}>
                    <div style={{fontSize:12,fontWeight:800,color:String(col)}}>{val||'—'}</div>
                    <div style={{width:'100%',height:`${h||5}%`,background:`linear-gradient(180deg,${col},${col}55)`,borderRadius:'6px 6px 0 0',transition:'height .8s ease',boxShadow:h>0?`0 -2px 8px ${col}33`:undefined}}/>
                    <div style={{fontSize:9,color:C.sub,textAlign:'center',lineHeight:1.3}}>{label}</div>
                  </div>
                )
              })}
            </div>
          </div>
          <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:18,marginBottom:18,backdropFilter:'blur(14px)'}}>
            <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:dm?C.text:C.textL,marginBottom:14}}>{t('Subject-wise Breakdown','विषय-वार विभाजन')}</div>
            {[{n:t('Physics','भौतिकी'),icon:'⚛️',mine:results[0]?.subjectScores?.physics,top:leaders[0]?.subjectScores?.physics||165,tot:180,col:'#00B4FF'},{n:t('Chemistry','रसायन'),icon:'🧪',mine:results[0]?.subjectScores?.chemistry,top:leaders[0]?.subjectScores?.chemistry||168,tot:180,col:'#FF6B9D'},{n:t('Biology','जीव विज्ञान'),icon:'🧬',mine:results[0]?.subjectScores?.biology,top:leaders[0]?.subjectScores?.biology||340,tot:360,col:'#00E5A0'}].map(s=>(
              <div key={s.n} style={{marginBottom:14,padding:'10px',background:'rgba(77,159,255,.04)',borderRadius:9}}>
                <div style={{display:'flex',justifyContent:'space-between',marginBottom:7,fontSize:12}}>
                  <span style={{fontWeight:700,color:s.col}}>{s.icon} {s.n}</span>
                  <div style={{display:'flex',gap:12}}>
                    <span style={{color:C.primary}}>{t('You','आप')}: {s.mine??'—'}</span>
                    <span style={{color:C.gold}}>{t('Top','टॉप')}: {s.top}</span>
                    <span style={{color:C.sub}}>/{s.tot}</span>
                  </div>
                </div>
                <div style={{position:'relative',height:11,background:'rgba(255,255,255,.06)',borderRadius:5,overflow:'hidden'}}>
                  <div style={{position:'absolute',top:0,left:0,height:'100%',width:`${(s.top/s.tot)*100}%`,background:`${C.gold}44`,borderRadius:5}}/>
                  {s.mine!=null&&<div style={{position:'absolute',top:0,left:0,height:'100%',width:`${(s.mine/s.tot)*100}%`,background:`linear-gradient(90deg,${s.col}88,${s.col})`,borderRadius:5}}/>}
                </div>
              </div>
            ))}
          </div>
          {leaders.length>0&&(
            <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:14,overflow:'hidden',backdropFilter:'blur(14px)'}}>
              <div style={{padding:'12px 18px',borderBottom:`1px solid ${C.border}`,fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:13,color:dm?C.text:C.textL}}>🏆 {t('Top 5 Performers','शीर्ष 5 प्रदर्शनकर्ता')}</div>
              {leaders.slice(0,5).map((l:any,i:number)=>(
                <div key={l._id||i} style={{display:'flex',alignItems:'center',gap:10,padding:'10px 18px',borderBottom:`1px solid ${C.border}`}}>
                  <span style={{width:26,height:26,borderRadius:'50%',background:i===0?`linear-gradient(135deg,${C.gold},#FF8C00)`:i===1?'linear-gradient(135deg,#C0C0C0,#808080)':i===2?'linear-gradient(135deg,#CD7F32,#8B4513)':'rgba(77,159,255,.15)',display:'flex',alignItems:'center',justifyContent:'center',fontWeight:700,fontSize:10,color:i<3?'#000':C.primary,flexShrink:0}}>{i+1}</span>
                  <span style={{flex:1,fontWeight:600,fontSize:12,color:dm?C.text:C.textL}}>{l.studentName||l.name||'—'}</span>
                  <span style={{fontWeight:700,fontSize:13,color:C.primary}}>{l.score||'—'}/720</span>
                </div>
              ))}
            </div>
          )}
        </>
      )}
    </div>
  )
}
export default function ComparePage() {
  return <StudentShell pageKey="compare"><CompareContent/></StudentShell>
}
