'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const C = { primary:'#4D9FFF', card:'rgba(0,22,40,0.80)', border:'rgba(77,159,255,0.22)', text:'#E8F4FF', sub:'#6B8FAF', success:'#00C48C', gold:'#FFD700', danger:'#FF4D4D', warn:'#FFB84D' }

export default function GoalsPage() {
  return (
    <StudentShell pageKey="goals">
      {({lang, darkMode:dm, user, toast, token}) => {
        const [targetRank, setTargetRank] = useState('100')
        const [targetScore, setTargetScore] = useState('650')
        const [targetDate, setTargetDate] = useState('2026-05-03')
        const [saving, setSaving] = useState(false)
        const [results, setResults] = useState<any[]>([])

        useEffect(()=>{
          if(user?.goals){setTargetRank(user.goals.rank||'100');setTargetScore(user.goals.score||'650')}
          if(!token) return
          fetch(`${API}/api/results`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>setResults(Array.isArray(d)?d:[])).catch(()=>{})
        },[user,token])

        const saveGoals = async () => {
          if(!token) return
          setSaving(true)
          try {
            const res = await fetch(`${API}/api/auth/me`,{method:'PATCH',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({goals:{rank:parseInt(targetRank),score:parseInt(targetScore),targetDate}})})
            if(res.ok) toast(lang==='en'?'Goals saved! Keep going! 🎯':'लक्ष्य सहेजे! आगे बढ़ते रहो! 🎯','s')
            else toast('Failed to save','e')
          } catch{toast('Network error','e')}
          setSaving(false)
        }

        const currentBestScore = results.length>0?Math.max(...results.map((r:any)=>r.score||0)):0
        const currentBestRank = results.length>0?Math.min(...results.map((r:any)=>r.rank||99999)):99999
        const scoreProgress = Math.min(100,Math.round((currentBestScore/parseInt(targetScore||'720'))*100))
        const rankProgress = currentBestRank<99999?Math.min(100,Math.round((1-((currentBestRank-parseInt(targetRank||'100'))/(10000)))*100)):0
        const daysLeft = Math.max(0,Math.ceil((new Date(targetDate).getTime()-Date.now())/(1000*60*60*24)))

        const inp:any={width:'100%',padding:'12px 14px',background:'rgba(0,22,40,0.85)',border:`1.5px solid rgba(77,159,255,0.3)`,borderRadius:10,color:C.text,fontSize:14,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box'}

        const milestones = lang==='en'?[{done:results.length>0,text:'Give first mock test'},{done:currentBestScore>400,text:'Score above 400/720'},{done:currentBestScore>500,text:'Score above 500/720'},{done:currentBestScore>600,text:'Score above 600/720'},{done:currentBestRank<1000,text:'Rank under 1000'},{done:currentBestRank<500,text:'Rank under 500'}]:[{done:results.length>0,text:'पहला मॉक टेस्ट दें'},{done:currentBestScore>400,text:'400/720 से अधिक स्कोर'},{done:currentBestScore>500,text:'500/720 से अधिक स्कोर'},{done:currentBestScore>600,text:'600/720 से अधिक स्कोर'},{done:currentBestRank<1000,text:'1000 से कम रैंक'},{done:currentBestRank<500,text:'500 से कम रैंक'}]

        return (
          <div style={{animation:'fadeIn .4s ease'}}>
            <div style={{marginBottom:20}}>
              <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.gold},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>{lang==='en'?'My Goals':'मेरे लक्ष्य'} (N1)</h1>
              <div style={{fontSize:13,color:C.sub}}>{lang==='en'?'Set your target rank & score — track your progress every day':'अपना लक्ष्य रैंक और स्कोर सेट करें — हर दिन प्रगति ट्रैक करें'}</div>
            </div>

            {/* Quote Banner */}
            <div style={{background:'linear-gradient(135deg,rgba(255,215,0,0.12),rgba(0,22,40,0.9))',border:`1px solid rgba(255,215,0,0.3)`,borderRadius:20,padding:'20px',marginBottom:24,display:'flex',alignItems:'center',gap:16,position:'relative',overflow:'hidden'}}>
              <div style={{position:'absolute',right:16,opacity:.08}}>
                <svg width="120" height="100" viewBox="0 0 120 100" fill="none">
                  <path d="M60 10 L70 38 L100 38 L76 55 L85 83 L60 66 L35 83 L44 55 L20 38 L50 38 Z" stroke="#FFD700" strokeWidth="2" fill="none"/>
                  <path d="M60 28 L66 44 L84 44 L70 53 L75 70 L60 61 L45 70 L50 53 L36 44 L54 44 Z" fill="rgba(255,215,0,0.2)"/>
                </svg>
              </div>
              <span style={{fontSize:32}}>🎯</span>
              <div style={{flex:1}}>
                <div style={{fontSize:14,color:C.gold,fontStyle:'italic',fontWeight:700,marginBottom:3}}>{lang==='en'?'"A goal without a plan is just a wish — make your plan today."':'"योजना के बिना लक्ष्य बस एक इच्छा है — आज अपनी योजना बनाएं।"'}</div>
                <div style={{fontSize:11,color:C.sub}}>{daysLeft} {lang==='en'?`days remaining to reach your goal (${new Date(targetDate).toLocaleDateString('en-IN',{day:'numeric',month:'short',year:'numeric'})})`:`दिन शेष (${new Date(targetDate).toLocaleDateString('en-IN',{day:'numeric',month:'short',year:'numeric'})})`}</div>
              </div>
            </div>

            {/* Goal Setting Form */}
            <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:24,marginBottom:20,backdropFilter:'blur(12px)'}}>
              <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:'#0F172A',marginBottom:16}}>🎯 {lang==='en'?'Set Your Target':'अपना लक्ष्य सेट करें'}</div>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:14,marginBottom:14}}>
                <div>
                  <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:6,textTransform:'uppercase'}}>{lang==='en'?'Target AIR Rank':'लक्ष्य AIR रैंक'}</label>
                  <input type="number" value={targetRank} onChange={e=>setTargetRank(e.target.value)} style={inp} placeholder="e.g. 100" min="1" max="100000"/>
                </div>
                <div>
                  <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:6,textTransform:'uppercase'}}>{lang==='en'?'Target Score (out of 720)':'लक्ष्य स्कोर (720 में से)'}</label>
                  <input type="number" value={targetScore} onChange={e=>setTargetScore(e.target.value)} style={inp} placeholder="e.g. 650" min="0" max="720"/>
                </div>
                <div style={{gridColumn:'1/-1'}}>
                  <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:6,textTransform:'uppercase'}}>{lang==='en'?'Target Date':'लक्ष्य तारीख'}</label>
                  <input type="date" value={targetDate} onChange={e=>setTargetDate(e.target.value)} style={inp}/>
                </div>
              </div>
              <button onClick={saveGoals} disabled={saving} className="btn-p" style={{width:'100%',opacity:saving?.7:1}}>
                {saving?'⟳ Saving...':lang==='en'?'💾 Save Goals':'💾 लक्ष्य सहेजें'}
              </button>
            </div>

            {/* Progress Cards */}
            <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:14,marginBottom:20}}>
              {[[lang==='en'?'Score Progress':'स्कोर प्रगति',currentBestScore,parseInt(targetScore||'720'),scoreProgress,C.primary,'📊'],[lang==='en'?'Rank Progress':'रैंक प्रगति',currentBestRank<99999?`#${currentBestRank}`:'—',`#${targetRank}`,rankProgress,C.gold,'🏆']].map(([title,current,target2,progress,col,icon])=>(
                <div key={String(title)} style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:20,backdropFilter:'blur(12px)'}}>
                  <div style={{fontWeight:700,fontSize:13,color:dm?C.text:'#0F172A',marginBottom:14}}>{icon} {title}</div>
                  <div style={{display:'flex',justifyContent:'space-between',marginBottom:8,fontSize:11}}>
                    <div style={{textAlign:'center'}}>
                      <div style={{fontWeight:800,fontSize:20,color:String(col)}}>{current}</div>
                      <div style={{color:C.sub}}>{lang==='en'?'Current':'वर्तमान'}</div>
                    </div>
                    <div style={{fontSize:20,color:C.sub}}>→</div>
                    <div style={{textAlign:'center'}}>
                      <div style={{fontWeight:800,fontSize:20,color:C.success}}>{String(target2)}</div>
                      <div style={{color:C.sub}}>{lang==='en'?'Target':'लक्ष्य'}</div>
                    </div>
                  </div>
                  <div style={{background:'rgba(255,255,255,0.06)',borderRadius:6,height:10,overflow:'hidden',marginBottom:6}}>
                    <div style={{height:'100%',width:`${progress}%`,background:`linear-gradient(90deg,${col}88,${col})`,borderRadius:6,transition:'width .8s'}}/>
                  </div>
                  <div style={{fontSize:11,color:String(col),textAlign:'right',fontWeight:600}}>{progress}% {lang==='en'?'achieved':'प्राप्त'}</div>
                </div>
              ))}
            </div>

            {/* Milestones */}
            <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:20,backdropFilter:'blur(12px)'}}>
              <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:'#0F172A',marginBottom:14}}>🏅 {lang==='en'?'Achievement Milestones':'उपलब्धि मील-पत्थर'}</div>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8}}>
                {milestones.map((m,i)=>(
                  <div key={i} style={{display:'flex',alignItems:'center',gap:10,padding:'10px 14px',background:m.done?'rgba(0,196,140,0.08)':'rgba(255,255,255,0.04)',border:`1px solid ${m.done?'rgba(0,196,140,0.3)':C.border}`,borderRadius:10}}>
                    <span style={{fontSize:16}}>{m.done?'✅':'⭕'}</span>
                    <span style={{fontSize:12,color:m.done?C.success:C.sub,fontWeight:m.done?600:400}}>{m.text}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )
      }}
    </StudentShell>
  )
}
