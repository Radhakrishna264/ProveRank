'use client'
import { useState, useEffect } from 'react'
import StudentShell from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const C = { primary:'#4D9FFF', card:'rgba(0,22,40,0.80)', border:'rgba(77,159,255,0.22)', text:'#E8F4FF', sub:'#6B8FAF', success:'#00C48C', gold:'#FFD700', danger:'#FF4D4D', warn:'#FFB84D' }

export default function MiniTestsPage() {
  return (
    <StudentShell pageKey="mini-tests">
      {({lang, darkMode:dm, user, toast, token}) => {
        const [exams, setExams] = useState<any[]>([])
        const [loading, setLoading] = useState(true)
        const [selSubj, setSelSubj] = useState('all')

        useEffect(()=>{
          if(!token) return
          fetch(`${API}/api/exams`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{
            const list = Array.isArray(d)?d.filter((e:any)=>e.duration<=70||e.category==='Chapter Test'||e.category==='Part Test'):[]
            setExams(list); setLoading(false)
          }).catch(()=>setLoading(false))
        },[token])

        const subjects = ['Physics','Chemistry','Biology']
        const chapterTopics:{[key:string]:string[]} = {
          Physics:['Electrostatics','Mechanics','Thermodynamics','Optics','Modern Physics','Magnetism'],
          Chemistry:['Organic Chemistry','Inorganic Chemistry','Physical Chemistry','Chemical Bonding','Equilibrium'],
          Biology:['Genetics','Cell Biology','Human Physiology','Plant Biology','Ecology','Evolution']
        }

        return (
          <div style={{animation:'fadeIn .4s ease'}}>
            <div style={{marginBottom:20}}>
              <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>{lang==='en'?'Mini Tests':'मिनी टेस्ट'} (S103)</h1>
              <div style={{fontSize:13,color:C.sub}}>{lang==='en'?'Chapter & topic wise quick tests — 15-20 minutes, focused preparation':'अध्याय और विषय-वार त्वरित टेस्ट — 15-20 मिनट, केंद्रित तैयारी'}</div>
            </div>

            {/* Banner */}
            <div style={{background:'linear-gradient(135deg,rgba(0,196,140,0.1),rgba(0,22,40,0.85))',border:`1px solid rgba(0,196,140,0.2)`,borderRadius:20,padding:'20px',marginBottom:24,position:'relative',overflow:'hidden'}}>
              <div style={{position:'absolute',right:16,top:'50%',transform:'translateY(-50%)',opacity:.08}}>
                <svg width="120" height="100" viewBox="0 0 120 100" fill="none">
                  <circle cx="60" cy="50" r="40" stroke="#00C48C" strokeWidth="1.5" strokeDasharray="5 3"/>
                  <path d="M40 50 L55 65 L80 35" stroke="#00C48C" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"/>
                  <circle cx="20" cy="20" r="5" fill="#4D9FFF" opacity=".5"/>
                  <circle cx="100" cy="25" r="4" fill="#FFD700" opacity=".5"/>
                  <circle cx="105" cy="85" r="6" fill="#00C48C" opacity=".4"/>
                </svg>
              </div>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:C.success,marginBottom:4}}>{lang==='en'?'⚡ Quick chapter-wise mastery':'⚡ त्वरित अध्याय-वार महारत'}</div>
              <div style={{fontSize:12,color:C.sub,maxWidth:500}}>{lang==='en'?'"Small consistent efforts build big results — one chapter at a time."':'"छोटे नियमित प्रयास बड़े परिणाम बनाते हैं — एक अध्याय एक बार।"'}</div>
            </div>

            {/* Subject Filter */}
            <div style={{display:'flex',gap:8,marginBottom:20,flexWrap:'wrap'}}>
              {['all',...subjects].map(s=>(
                <button key={s} onClick={()=>setSelSubj(s)} style={{padding:'9px 16px',borderRadius:10,border:`1px solid ${selSubj===s?C.primary:C.border}`,background:selSubj===s?`${C.primary}22`:C.card,color:selSubj===s?C.primary:C.sub,cursor:'pointer',fontSize:12,fontWeight:selSubj===s?700:400,fontFamily:'Inter,sans-serif'}}>
                  {s==='all'?(lang==='en'?'All':'सभी'):s==='Physics'?'⚛️ '+(lang==='en'?'Physics':'भौतिकी'):s==='Chemistry'?'🧪 '+(lang==='en'?'Chemistry':'रसायन'):'🧬 '+(lang==='en'?'Biology':'जीव विज्ञान')}
                </button>
              ))}
            </div>

            {/* Chapter Topic Cards */}
            {(selSubj==='all'?subjects:[selSubj]).map(subj=>(
              <div key={subj} style={{marginBottom:24}}>
                <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:16,color:subj==='Physics'?'#00B4FF':subj==='Chemistry'?'#FF6B9D':'#00E5A0',marginBottom:12}}>
                  {subj==='Physics'?'⚛️':subj==='Chemistry'?'🧪':'🧬'} {lang==='en'?subj:subj==='Physics'?'भौतिकी':subj==='Chemistry'?'रसायन':'जीव विज्ञान'}
                </div>
                <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(180px,1fr))',gap:10}}>
                  {(chapterTopics[subj]||[]).map((topic,i)=>(
                    <div key={i} className="card-h" style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:14,padding:16,backdropFilter:'blur(12px)',transition:'all .2s'}}>
                      <div style={{fontSize:22,marginBottom:8}}>{['⚡','🔬','💡','🧲','🌊','🔭','🧫','🌱','🦠','🧬','🔋','💊'][i%12]}</div>
                      <div style={{fontWeight:700,fontSize:13,color:dm?C.text:'#0F172A',marginBottom:4}}>{topic}</div>
                      <div style={{fontSize:10,color:C.sub,marginBottom:12}}>15-20 {lang==='en'?'min · 15-20 Qs':'मिनट · 15-20 प्रश्न'}</div>
                      <a href="/my-exams" style={{display:'block',padding:'7px',background:`linear-gradient(135deg,${C.primary},#0055CC)`,color:'#fff',borderRadius:8,textDecoration:'none',fontWeight:700,fontSize:11,textAlign:'center'}}>
                        {lang==='en'?'Start Test →':'टेस्ट शुरू करें →'}
                      </a>
                    </div>
                  ))}
                </div>
              </div>
            ))}

            {/* Scheduled Mini Tests from DB */}
            {exams.length>0&&(
              <div>
                <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:16,color:dm?C.text:'#0F172A',marginBottom:12}}>📋 {lang==='en'?'Scheduled Mini Tests':'निर्धारित मिनी टेस्ट'}</div>
                {exams.map((e:any)=>(
                  <div key={e._id} style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:12,padding:16,marginBottom:8,display:'flex',justifyContent:'space-between',alignItems:'center',backdropFilter:'blur(12px)',flexWrap:'wrap',gap:10}}>
                    <div>
                      <div style={{fontWeight:700,fontSize:13,color:dm?C.text:'#0F172A'}}>{e.title}</div>
                      <div style={{fontSize:11,color:C.sub,marginTop:3}}>⏱️ {e.duration} min · 🎯 {e.totalMarks} marks · 📅 {new Date(e.scheduledAt).toLocaleDateString('en-IN',{day:'numeric',month:'short'})}</div>
                    </div>
                    <a href={`/exam/${e._id}`} className="btn-p" style={{textDecoration:'none',fontSize:12}}>{lang==='en'?'Start →':'शुरू करें →'}</a>
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
