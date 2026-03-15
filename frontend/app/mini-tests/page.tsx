'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

function MiniTestsContent() {
  const { lang, darkMode:dm, toast, token } = useShell()
  const [exams,   setExams]   = useState<any[]>([])
  const [selSubj, setSelSubj] = useState('all')
  const [loading, setLoading] = useState(true)
  const t = (en:string, hi:string) => lang==='en' ? en : hi

  useEffect(()=>{
    if(!token) return
    fetch(`${API}/api/exams`,{headers:{Authorization:`Bearer ${token}`}})
      .then(r=>r.ok?r.json():[]).then(d=>{
        const list=Array.isArray(d)?d.filter((e:any)=>e.duration<=70||e.category==='Chapter Test'||e.category==='Part Test'):[]
        setExams(list); setLoading(false)
      }).catch(()=>setLoading(false))
  },[token])

  const chapters:{[k:string]:string[]} = {
    Physics:['Electrostatics','Mechanics','Thermodynamics','Optics','Modern Physics','Magnetism'],
    Chemistry:['Organic Chemistry','Inorganic Chemistry','Physical Chemistry','Chemical Bonding','Equilibrium'],
    Biology:['Genetics','Cell Biology','Human Physiology','Plant Biology','Ecology','Evolution']
  }
  const subjects = ['Physics','Chemistry','Biology']
  const subjHi:{[k:string]:string} = {Physics:'भौतिकी',Chemistry:'रसायन',Biology:'जीव विज्ञान'}
  const subjCol:{[k:string]:string} = {Physics:'#00B4FF',Chemistry:'#FF6B9D',Biology:'#00E5A0'}
  const subjIcon:{[k:string]:string}= {Physics:'⚛️',Chemistry:'🧪',Biology:'🧬'}

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>⚡ {t('Mini Tests','मिनी टेस्ट')} (S103)</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('Chapter-wise quick tests — 15-20 mins, focused preparation','अध्याय-वार त्वरित टेस्ट — 15-20 मिनट, केंद्रित तैयारी')}</div>

      <div style={{background:'linear-gradient(135deg,rgba(0,196,140,.1),rgba(0,22,40,.85))',border:'1px solid rgba(0,196,140,.2)',borderRadius:18,padding:18,marginBottom:22,display:'flex',alignItems:'center',gap:14}}>
        <span style={{fontSize:28}}>⚡</span>
        <div style={{fontSize:13,color:C.success,fontStyle:'italic',fontWeight:700}}>{t('"Small consistent efforts build big results — one chapter at a time."','"छोटे नियमित प्रयास बड़े परिणाम बनाते हैं — एक अध्याय एक बार।"')}</div>
      </div>

      <div style={{display:'flex',gap:8,marginBottom:20,flexWrap:'wrap'}}>
        {['all',...subjects].map(s=>(
          <button key={s} onClick={()=>setSelSubj(s)} style={{padding:'8px 16px',borderRadius:9,border:`1px solid ${selSubj===s?C.primary:C.border}`,background:selSubj===s?`${C.primary}22`:C.card,color:selSubj===s?C.primary:C.sub,cursor:'pointer',fontSize:12,fontWeight:selSubj===s?700:400,fontFamily:'Inter,sans-serif'}}>
            {s==='all'?t('All Subjects','सभी विषय'):`${subjIcon[s]} ${t(s,subjHi[s])}`}
          </button>
        ))}
      </div>

      {(selSubj==='all'?subjects:[selSubj]).map(subj=>(
        <div key={subj} style={{marginBottom:24}}>
          <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:16,color:subjCol[subj],marginBottom:12}}>{subjIcon[subj]} {t(subj,subjHi[subj])}</div>
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(160px,1fr))',gap:10}}>
            {(chapters[subj]||[]).map((topic,i)=>(
              <div key={i} className="card-h" style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:13,padding:14,backdropFilter:'blur(12px)',transition:'all .2s'}}>
                <div style={{fontSize:22,marginBottom:7}}>{['⚡','🔬','💡','🧲','🌊','🔭','🧫','🌱','🦠','🧬','🔋','💊'][i%12]}</div>
                <div style={{fontWeight:700,fontSize:12,color:dm?C.text:C.textL,marginBottom:3}}>{topic}</div>
                <div style={{fontSize:10,color:C.sub,marginBottom:10}}>15-20 {t('min · 15 Qs','मिनट · 15 प्रश्न')}</div>
                <a href="/my-exams" style={{display:'block',padding:'6px',background:`linear-gradient(135deg,${C.primary},#0055CC)`,color:'#fff',borderRadius:7,textDecoration:'none',fontWeight:700,fontSize:11,textAlign:'center'}}>{t('Start →','शुरू →')}</a>
              </div>
            ))}
          </div>
        </div>
      ))}

      {!loading&&exams.length>0&&(
        <div>
          <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:C.textL,marginBottom:12}}>📋 {t('Scheduled Mini Tests','निर्धारित मिनी टेस्ट')}</div>
          {exams.map((e:any)=>(
            <div key={e._id} style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:12,padding:14,marginBottom:8,display:'flex',justifyContent:'space-between',alignItems:'center',backdropFilter:'blur(12px)',flexWrap:'wrap',gap:8}}>
              <div>
                <div style={{fontWeight:700,fontSize:13,color:dm?C.text:C.textL}}>{e.title}</div>
                <div style={{fontSize:11,color:C.sub,marginTop:2}}>⏱️ {e.duration} min · 🎯 {e.totalMarks} marks · 📅 {new Date(e.scheduledAt).toLocaleDateString('en-IN',{day:'numeric',month:'short'})}</div>
              </div>
              <a href={`/exam/${e._id}`} className="btn-p" style={{textDecoration:'none',fontSize:11}}>{t('Start →','शुरू →')}</a>
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
