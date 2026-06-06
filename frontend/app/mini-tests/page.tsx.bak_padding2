'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
function MiniTestsContent() {
  const {lang,darkMode:dm,toast,token}=useShell()
  const [selSubj,setSelSubj]=useState('all')
  const [scheduled,setScheduled]=useState<any[]>([])
  const t=(en:string,hi:string)=>lang==='en'?en:hi
  useEffect(()=>{
    if(!token) return
    fetch(`${API}/api/exams`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{
      setScheduled(Array.isArray(d)?d.filter((e:any)=>e.duration<=70||e.category==='Chapter Test'||e.category==='Part Test'):[])
    }).catch(()=>{})
  },[token])
  const chapters:{[k:string]:{name:string;emoji:string}[]}={
    Physics:[{name:'Electrostatics',emoji:'⚡'},{name:'Mechanics',emoji:'⚙️'},{name:'Thermodynamics',emoji:'🔥'},{name:'Optics',emoji:'🔭'},{name:'Modern Physics',emoji:'⚛️'},{name:'Magnetism',emoji:'🧲'}],
    Chemistry:[{name:'Organic Chemistry',emoji:'🧪'},{name:'Inorganic Chemistry',emoji:'🏭'},{name:'Physical Chemistry',emoji:'⚗️'},{name:'Chemical Bonding',emoji:'🔗'},{name:'Equilibrium',emoji:'⚖️'}],
    Biology:[{name:'Genetics',emoji:'🧬'},{name:'Cell Biology',emoji:'🦠'},{name:'Human Physiology',emoji:'🫀'},{name:'Plant Biology',emoji:'🌱'},{name:'Ecology',emoji:'🌍'},{name:'Evolution',emoji:'🦎'}]
  }
  const subjectColors:{[k:string]:string}={Physics:'#00B4FF',Chemistry:'#FF6B9D',Biology:'#00E5A0'}
  const subjects=['Physics','Chemistry','Biology']
  const subjectHi:{[k:string]:string}={Physics:'भौतिकी',Chemistry:'रसायन',Biology:'जीव विज्ञान'}
  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>⚡ {t('Mini Tests','मिनी टेस्ट')} (S103)</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('Chapter-wise quick tests — 15-20 mins, focused prep','अध्याय-वार त्वरित टेस्ट — 15-20 मिनट')}</div>
      <div style={{background:'linear-gradient(135deg,rgba(0,196,140,.1),rgba(0,22,40,.88))',border:'1px solid rgba(0,196,140,.22)',borderRadius:18,padding:18,marginBottom:22,display:'flex',alignItems:'center',gap:14}}>
        <svg width="65" height="75" viewBox="0 0 65 75" fill="none" style={{animation:'floatR 5s ease-in-out infinite',flexShrink:0}}>
          <path d="M20 10 H45 V60 Q45 70 32.5 70 Q20 70 20 60 Z" stroke="#00C48C" strokeWidth="1.5" fill="rgba(0,196,140,0.12)"/>
          <line x1="14" y1="10" x2="20" y2="10" stroke="#00C48C" strokeWidth="2"/>
          <line x1="45" y1="10" x2="51" y2="10" stroke="#00C48C" strokeWidth="2"/>
          <line x1="20" y1="35" x2="45" y2="35" stroke="rgba(0,196,140,0.4)" strokeWidth="1" strokeDasharray="3 2"/>
          <line x1="20" y1="48" x2="45" y2="48" stroke="rgba(0,196,140,0.4)" strokeWidth="1" strokeDasharray="3 2"/>
          <circle cx="55" cy="20" r="4" fill="#FFD700" opacity=".7"/>
          <circle cx="10" cy="45" r="3" fill="#4D9FFF" opacity=".7"/>
        </svg>
        <div style={{flex:1}}>
          <div style={{fontSize:14,color:C.success,fontStyle:'italic',fontWeight:700,marginBottom:3}}>{t('"Small consistent efforts build big results — one chapter at a time."','"छोटे नियमित प्रयास बड़े परिणाम बनाते हैं।"')}</div>
          <div style={{fontSize:11,color:C.sub}}>{t('Select a subject and chapter to start a focused mini test','विषय और अध्याय चुनें और फ़ोकस्ड मिनी टेस्ट शुरू करें')}</div>
        </div>
      </div>
      <div style={{display:'flex',gap:8,marginBottom:20,flexWrap:'wrap'}}>
        {['all',...subjects].map(s=>(
          <button key={s} onClick={()=>setSelSubj(s)} style={{padding:'8px 16px',borderRadius:9,border:`1px solid ${selSubj===s?C.primary:C.border}`,background:selSubj===s?`${C.primary}22`:C.card,color:selSubj===s?C.primary:C.sub,cursor:'pointer',fontSize:12,fontWeight:selSubj===s?700:400,fontFamily:'Inter,sans-serif',transition:'all .2s'}}>
            {s==='all'?t('All Subjects','सभी विषय'):t(s,subjectHi[s])}
          </button>
        ))}
      </div>
      {(selSubj==='all'?subjects:[selSubj]).map(subj=>(
        <div key={subj} style={{marginBottom:24}}>
          <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:16,color:subjectColors[subj],marginBottom:12,display:'flex',alignItems:'center',gap:8}}>
            <span>{subj==='Physics'?'⚛️':subj==='Chemistry'?'🧪':'🧬'}</span>
            <span>{t(subj,subjectHi[subj])}</span>
          </div>
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(150px,1fr))',gap:10}}>
            {(chapters[subj]||[]).map((ch,i)=>(
              <div key={i} className="card-h" style={{background:dm?C.card:C.cardL,border:`1px solid ${subjectColors[subj]}22`,borderRadius:13,padding:14,backdropFilter:'blur(14px)',transition:'all .25s',boxShadow:'0 2px 10px rgba(0,0,0,.1)'}}>
                <div style={{fontSize:24,marginBottom:8}}>{ch.emoji}</div>
                <div style={{fontWeight:700,fontSize:12,color:dm?C.text:C.textL,marginBottom:3}}>{ch.name}</div>
                <div style={{fontSize:10,color:C.sub,marginBottom:10}}>15-20 {t('min · 15 Qs','मिनट · 15 प्रश्न')}</div>
                <a href="/my-exams" style={{display:'block',padding:'6px',background:`linear-gradient(135deg,${subjectColors[subj]},${subjectColors[subj]}88)`,color:'#000',borderRadius:7,textDecoration:'none',fontWeight:700,fontSize:11,textAlign:'center'}}>{t('Start →','शुरू →')}</a>
              </div>
            ))}
          </div>
        </div>
      ))}
      {scheduled.length>0&&(
        <div>
          <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:C.textL,marginBottom:12}}>📋 {t('Scheduled Mini Tests','निर्धारित मिनी टेस्ट')}</div>
          {scheduled.map((e:any)=>(
            <div key={e._id} style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:12,padding:14,marginBottom:8,display:'flex',justifyContent:'space-between',alignItems:'center',backdropFilter:'blur(14px)',flexWrap:'wrap',gap:8}}>
              <div>
                <div style={{fontWeight:700,fontSize:13,color:dm?C.text:C.textL}}>{e.title}</div>
                <div style={{fontSize:11,color:C.sub,marginTop:2}}>⏱️ {e.duration} min · 🎯 {e.totalMarks} marks · 📅 {new Date(e.scheduledAt).toLocaleDateString('en-IN',{day:'numeric',month:'short'})}</div>
              </div>
              <a href={`/exam/${e._id}`} className="btn-p" style={{textDecoration:'none',fontSize:12}}>{t('Start →','शुरू →')}</a>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
export default function MiniTestsPage() {
  return <StudentShell pageKey="mini-tests"><MiniTestsContent/></StudentShell>
}
