'use client'
import { useState, useEffect } from 'react'
import StudentShell from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const C = { primary:'#4D9FFF', card:'rgba(0,22,40,0.80)', border:'rgba(77,159,255,0.22)', text:'#E8F4FF', sub:'#6B8FAF', success:'#00C48C', gold:'#FFD700', danger:'#FF4D4D', warn:'#FFB84D' }

export default function ComparePage() {
  return (
    <StudentShell pageKey="compare">
      {({lang, darkMode:dm, user, toast, token}) => {
        const [myResults, setMyResults] = useState<any[]>([])
        const [leaders, setLeaders] = useState<any[]>([])
        const [loading, setLoading] = useState(true)

        useEffect(()=>{
          if(!token) return
          const h={Authorization:`Bearer ${token}`}
          Promise.all([
            fetch(`${API}/api/results`,{headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[]),
            fetch(`${API}/api/results/leaderboard`,{headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[]),
          ]).then(([r,l])=>{setMyResults(Array.isArray(r)?r:[]);setLeaders(Array.isArray(l)?l:[]);setLoading(false)})
        },[token])

        const myAvg = myResults.length>0?Math.round(myResults.reduce((a,r)=>a+(r.score||0),0)/myResults.length):0
        const myBest = myResults.length>0?Math.max(...myResults.map(r=>r.score||0)):0
        const topperAvg = leaders.length>0?Math.round(leaders.slice(0,3).reduce((a:number,l:any)=>a+(l.score||0),0)/Math.min(3,leaders.length)):680
        const classAvg = leaders.length>0?Math.round(leaders.reduce((a:number,l:any)=>a+(l.score||0),0)/leaders.length):580

        const bars = [[lang==='en'?'Your Best':'आपका सर्वश्रेष्ठ',myBest,C.primary],[lang==='en'?'Your Avg':'आपका औसत',myAvg,C.primary+'88'],[lang==='en'?'Class Avg':'कक्षा औसत',classAvg,C.warn],[lang==='en'?'Top 3 Avg':'शीर्ष 3 औसत',topperAvg,C.gold]]

        return (
          <div style={{animation:'fadeIn .4s ease'}}>
            <div style={{marginBottom:20}}>
              <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>{lang==='en'?'Compare Performance':'प्रदर्शन तुलना'} (S43/S80)</h1>
              <div style={{fontSize:13,color:C.sub}}>{lang==='en'?'Your score vs topper vs class average — subject wise comparison':'आपका स्कोर vs टॉपर vs क्लास औसत — विषय-वार तुलना'}</div>
            </div>

            {/* SVG Banner */}
            <div style={{background:'linear-gradient(135deg,rgba(77,159,255,0.1),rgba(0,22,40,0.85))',border:`1px solid rgba(77,159,255,0.2)`,borderRadius:20,padding:'20px',marginBottom:24,position:'relative',overflow:'hidden'}}>
              <div style={{position:'absolute',right:16,opacity:.08}}>
                <svg width="130" height="100" viewBox="0 0 130 100" fill="none">
                  <rect x="15" y="40" width="25" height="50" rx="3" fill="#4D9FFF"/>
                  <rect x="52" y="20" width="25" height="70" rx="3" fill="#FFD700"/>
                  <rect x="90" y="55" width="25" height="35" rx="3" fill="#00C48C"/>
                  <path d="M10 95h110" stroke="#4D9FFF" strokeWidth=".8"/>
                </svg>
              </div>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:C.primary,marginBottom:4}}>{lang==='en'?'See where you stand':'देखें आप कहाँ खड़े हैं'}</div>
              <div style={{fontSize:12,color:C.sub}}>{lang==='en'?'"Know your competition — aim higher every day."':'"अपनी प्रतिस्पर्धा को जानो — हर दिन ऊंचाई की ओर।"'}</div>
            </div>

            {/* Comparison Chart */}
            <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:24,marginBottom:20,backdropFilter:'blur(12px)'}}>
              <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:'#0F172A',marginBottom:20}}>{lang==='en'?'Score Comparison (out of 720)':'स्कोर तुलना (720 में से)'}</div>
              {loading?<div style={{textAlign:'center',padding:'40px',color:C.sub}}>⟳ Loading...</div>:(
                <div style={{display:'flex',alignItems:'flex-end',gap:12,height:150}}>
                  {bars.map(([label,val,col])=>{
                    const h=Math.round(((val as number)/720)*100)
                    return (
                      <div key={String(label)} style={{flex:1,display:'flex',flexDirection:'column',alignItems:'center',gap:6}}>
                        <div style={{fontSize:13,fontWeight:800,color:String(col)}}>{val}</div>
                        <div style={{width:'100%',height:`${h}%`,background:`linear-gradient(180deg,${col},${col}55)`,borderRadius:'6px 6px 0 0',minHeight:4,transition:'height .8s ease',position:'relative'}}>
                          <div style={{position:'absolute',top:-1,left:0,right:0,height:3,background:String(col),borderRadius:2}}/>
                        </div>
                        <div style={{fontSize:10,color:C.sub,textAlign:'center',lineHeight:1.3}}>{label}</div>
                      </div>
                    )
                  })}
                </div>
              )}
            </div>

            {/* Subject-wise Comparison */}
            <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:20,marginBottom:20,backdropFilter:'blur(12px)'}}>
              <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:'#0F172A',marginBottom:16}}>{lang==='en'?'Subject-wise Breakdown':'विषय-वार विभाजन'}</div>
              {[{name:lang==='en'?'Physics':'भौतिकी',icon:'⚛️',mine:myResults[0]?.subjectScores?.physics||148,top:165,total:180,col:'#00B4FF'},{name:lang==='en'?'Chemistry':'रसायन',icon:'🧪',mine:myResults[0]?.subjectScores?.chemistry||152,top:168,total:180,col:'#FF6B9D'},{name:lang==='en'?'Biology':'जीव विज्ञान',icon:'🧬',mine:myResults[0]?.subjectScores?.biology||310,top:340,total:360,col:'#00E5A0'}].map(s=>(
                <div key={s.name} style={{marginBottom:16,padding:'12px',background:'rgba(77,159,255,0.04)',borderRadius:10}}>
                  <div style={{display:'flex',justifyContent:'space-between',marginBottom:8,fontSize:12}}>
                    <span style={{fontWeight:700,color:s.col}}>{s.icon} {s.name}</span>
                    <div style={{display:'flex',gap:14}}>
                      <span style={{color:C.primary}}>You: {s.mine}</span>
                      <span style={{color:C.gold}}>Top: {s.top}</span>
                      <span style={{color:C.sub}}>/{s.total}</span>
                    </div>
                  </div>
                  <div style={{position:'relative',height:12,background:'rgba(255,255,255,0.06)',borderRadius:6,overflow:'hidden'}}>
                    <div style={{position:'absolute',top:0,left:0,height:'100%',width:`${(s.top/s.total)*100}%`,background:`${C.gold}44`,borderRadius:6}}/>
                    <div style={{position:'absolute',top:0,left:0,height:'100%',width:`${(s.mine/s.total)*100}%`,background:`linear-gradient(90deg,${s.col}88,${s.col})`,borderRadius:6}}/>
                  </div>
                </div>
              ))}
            </div>

            {/* Top Performers */}
            {leaders.length>0&&(
              <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,overflow:'hidden',backdropFilter:'blur(12px)'}}>
                <div style={{padding:'14px 20px',borderBottom:`1px solid ${C.border}`,fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:dm?C.text:'#0F172A'}}>🏆 {lang==='en'?'Top 5 Performers':'शीर्ष 5 प्रदर्शनकर्ता'}</div>
                {leaders.slice(0,5).map((l:any,i:number)=>(
                  <div key={l._id||i} style={{display:'flex',alignItems:'center',gap:12,padding:'12px 20px',borderBottom:`1px solid ${C.border}`}}>
                    <span style={{width:28,height:28,borderRadius:'50%',background:i===0?`linear-gradient(135deg,${C.gold},#FF8C00)`:i===1?'linear-gradient(135deg,#C0C0C0,#808080)':i===2?'linear-gradient(135deg,#CD7F32,#8B4513)':'rgba(77,159,255,0.15)',display:'flex',alignItems:'center',justifyContent:'center',fontWeight:700,fontSize:11,color:i<3?'#000':C.primary,flexShrink:0}}>{i+1}</span>
                    <div style={{flex:1}}>
                      <div style={{fontWeight:600,fontSize:13,color:dm?C.text:'#0F172A'}}>{l.studentName||l.name||'—'}</div>
                    </div>
                    <div style={{fontWeight:700,fontSize:14,color:C.primary}}>{l.score||'—'}/720</div>
                    {i===0&&<span>👑</span>}
                  </div>
                ))}
              </div>
            )}
          </div>
        )
      }}
    </StudentShell>
  )
}
