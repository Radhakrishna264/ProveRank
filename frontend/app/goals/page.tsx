'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const inp:any={width:'100%',padding:'11px 14px',background:'rgba(0,22,40,.85)',border:'1.5px solid rgba(77,159,255,.3)',borderRadius:10,color:'#E8F4FF',fontSize:13,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box'}

function GoalsContent() {
  const { lang, darkMode:dm, user, toast, token } = useShell()
  const [targetRank,  setTR] = useState('100')
  const [targetScore, setTS] = useState('650')
  const [targetDate,  setTD] = useState('2026-05-03')
  const [saving, setSaving] = useState(false)
  const [results, setResults]= useState<any[]>([])
  const t = (en:string, hi:string) => lang==='en' ? en : hi

  useEffect(()=>{
    if(user?.goals){setTR(String(user.goals.rank||100));setTS(String(user.goals.score||650))}
    if(!token) return
    fetch(`${API}/api/results`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>setResults(Array.isArray(d)?d:[])).catch(()=>{})
  },[user,token])

  const save = async () => {
    if(!token) return; setSaving(true)
    try {
      const r=await fetch(`${API}/api/auth/me`,{method:'PATCH',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({goals:{rank:parseInt(targetRank),score:parseInt(targetScore),targetDate}})})
      if(r.ok) toast(t('Goals saved! Keep going! 🎯','लक्ष्य सहेजे! आगे बढ़ते रहो! 🎯'),'s'); else toast('Failed','e')
    } catch { toast('Network error','e') }
    setSaving(false)
  }

  const curBest  = results.length ? Math.max(...results.map((r:any)=>r.score||0)) : 0
  const curRank  = results.length ? Math.min(...results.map((r:any)=>r.rank||99999)) : 99999
  const sPct     = curBest ? Math.min(100,Math.round((curBest/parseInt(targetScore||'720'))*100)) : 0
  const rPct     = curRank<99999 ? Math.min(100,Math.max(0,Math.round((1-((curRank-1)/(parseInt(targetRank||'100')+5000)))*100))) : 0
  const daysLeft = Math.max(0,Math.ceil((new Date(targetDate).getTime()-Date.now())/86400000))

  const milestones = lang==='en'?[{done:results.length>0,text:'Give first mock test'},{done:curBest>400,text:'Score above 400/720'},{done:curBest>500,text:'Score above 500/720'},{done:curBest>600,text:'Score above 600/720'},{done:curRank<1000,text:'Rank under 1000'},{done:curRank<500,text:'Rank under 500'}]:[{done:results.length>0,text:'पहला मॉक टेस्ट दें'},{done:curBest>400,text:'400/720 से अधिक'},{done:curBest>500,text:'500/720 से अधिक'},{done:curBest>600,text:'600/720 से अधिक'},{done:curRank<1000,text:'1000 से कम रैंक'},{done:curRank<500,text:'500 से कम रैंक'}]

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.gold},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>🎯 {t('My Goals','मेरे लक्ष्य')} (N1)</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('Set target rank & score — track daily progress','लक्ष्य रैंक और स्कोर सेट करें — दैनिक प्रगति ट्रैक करें')}</div>

      <div style={{background:'linear-gradient(135deg,rgba(255,215,0,.1),rgba(0,22,40,.9))',border:'1px solid rgba(255,215,0,.25)',borderRadius:18,padding:18,marginBottom:22,display:'flex',alignItems:'center',gap:14}}>
        <span style={{fontSize:28}}>🎯</span>
        <div>
          <div style={{fontSize:13,color:C.gold,fontStyle:'italic',fontWeight:700}}>{t('"A goal without a plan is just a wish — make your plan today."','"योजना के बिना लक्ष्य बस एक इच्छा है — आज अपनी योजना बनाएं।"')}</div>
          <div style={{fontSize:11,color:C.sub,marginTop:3}}>{daysLeft} {t('days to target','दिन शेष')} ({new Date(targetDate).toLocaleDateString('en-IN',{day:'numeric',month:'short',year:'numeric'})})</div>
        </div>
      </div>

      <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:22,marginBottom:18,backdropFilter:'blur(12px)'}}>
        <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:dm?C.text:C.textL,marginBottom:14}}>🎯 {t('Set Your Target','अपना लक्ष्य सेट करें')}</div>
        <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12,marginBottom:12}}>
          <div>
            <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase'}}>{t('Target AIR Rank','लक्ष्य AIR रैंक')}</label>
            <input type="number" value={targetRank} onChange={e=>setTR(e.target.value)} style={inp} min="1" max="100000"/>
          </div>
          <div>
            <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase'}}>{t('Target Score /720','लक्ष्य स्कोर /720')}</label>
            <input type="number" value={targetScore} onChange={e=>setTS(e.target.value)} style={inp} min="0" max="720"/>
          </div>
          <div style={{gridColumn:'1/-1'}}>
            <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase'}}>{t('Target Date','लक्ष्य तारीख')}</label>
            <input type="date" value={targetDate} onChange={e=>setTD(e.target.value)} style={inp}/>
          </div>
        </div>
        <button onClick={save} disabled={saving} className="btn-p" style={{width:'100%',opacity:saving?.7:1}}>{saving?'⟳ Saving...':t('💾 Save Goals','💾 लक्ष्य सहेजें')}</button>
      </div>

      <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12,marginBottom:18}}>
        {[[t('Score Progress','स्कोर प्रगति'),curBest?`${curBest}/720`:t('No tests','कोई टेस्ट नहीं'),`${targetScore}/720`,sPct,C.primary,'📊'],[t('Rank Progress','रैंक प्रगति'),curRank<99999?`#${curRank}`:t('No rank','—'),`#${targetRank}`,rPct,C.gold,'🏆']].map(([title,cur,tgt,pct,col,ic])=>(
          <div key={String(title)} style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:14,padding:18,backdropFilter:'blur(12px)'}}>
            <div style={{fontWeight:700,fontSize:12,color:dm?C.text:C.textL,marginBottom:12}}>{ic} {title}</div>
            <div style={{display:'flex',justifyContent:'space-between',marginBottom:8,fontSize:11}}>
              <div style={{textAlign:'center'}}><div style={{fontWeight:800,fontSize:18,color:String(col)}}>{cur}</div><div style={{color:C.sub,fontSize:9}}>{t('Current','वर्तमान')}</div></div>
              <div style={{fontSize:18,color:C.sub,alignSelf:'center'}}>→</div>
              <div style={{textAlign:'center'}}><div style={{fontWeight:800,fontSize:18,color:C.success}}>{tgt}</div><div style={{color:C.sub,fontSize:9}}>{t('Target','लक्ष्य')}</div></div>
            </div>
            <div style={{background:'rgba(255,255,255,.06)',borderRadius:5,height:9,overflow:'hidden',marginBottom:5}}>
              <div style={{height:'100%',width:`${pct}%`,background:`linear-gradient(90deg,${col}88,${col})`,borderRadius:5,transition:'width .8s'}}/>
            </div>
            <div style={{fontSize:10,color:String(col),textAlign:'right',fontWeight:600}}>{pct}% {t('achieved','प्राप्त')}</div>
          </div>
        ))}
      </div>

      <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:14,padding:18,backdropFilter:'blur(12px)'}}>
        <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:dm?C.text:C.textL,marginBottom:12}}>🏅 {t('Achievement Milestones','उपलब्धि मील-पत्थर')}</div>
        <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8}}>
          {milestones.map((m,i)=>(
            <div key={i} style={{display:'flex',alignItems:'center',gap:8,padding:'9px 12px',background:m.done?'rgba(0,196,140,.08)':'rgba(255,255,255,.03)',border:`1px solid ${m.done?'rgba(0,196,140,.3)':C.border}`,borderRadius:9}}>
              <span style={{fontSize:14}}>{m.done?'✅':'⭕'}</span>
              <span style={{fontSize:11,color:m.done?C.success:C.sub,fontWeight:m.done?600:400}}>{m.text}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
export default function GoalsPage() {
  return <StudentShell pageKey="goals"><GoalsContent/></StudentShell>
}
