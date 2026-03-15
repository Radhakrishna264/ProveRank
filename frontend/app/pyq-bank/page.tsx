'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const C = { primary:'#4D9FFF', card:'rgba(0,22,40,0.80)', border:'rgba(77,159,255,0.22)', text:'#E8F4FF', sub:'#6B8FAF', success:'#00C48C', gold:'#FFD700', danger:'#FF4D4D', warn:'#FFB84D' }

export default function PYQBankPage() {
  return (
    <StudentShell pageKey="pyq-bank">
      {({lang, darkMode:dm, user, toast, token}) => {
        const [year, setYear] = useState('all')
        const [subject, setSubject] = useState('all')
        const [questions, setQuestions] = useState<any[]>([])
        const [loading, setLoading] = useState(false)
        const [stats] = useState({total:1800,physics:450,chemistry:450,biology:900,years:10})

        const loadPYQ = async () => {
          if(!token) return
          setLoading(true)
          try {
            const params = new URLSearchParams()
            if(year!=='all') params.set('year',year)
            if(subject!=='all') params.set('subject',subject)
            const res = await fetch(`${API}/api/questions/pyq?${params}`,{headers:{Authorization:`Bearer ${token}`}})
            if(res.ok){const d=await res.json();setQuestions(Array.isArray(d)?d:(d.questions||[]))}
            else toast('PYQ data loading...','w')
          } catch{toast('Network error','e')}
          setLoading(false)
        }

        const years = ['2024','2023','2022','2021','2020','2019','2018','2017','2016','2015']

        return (
          <div style={{animation:'fadeIn .4s ease'}}>
            <div style={{marginBottom:20}}>
              <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>{lang==='en'?'PYQ Bank':'पिछले वर्ष के प्रश्न'} (S104)</h1>
              <div style={{fontSize:13,color:C.sub}}>{lang==='en'?'NEET Previous Year Questions 2015–2024 — Filter by year and subject':'NEET 2015–2024 पिछले वर्ष के प्रश्न — वर्ष और विषय से फ़िल्टर करें'}</div>
            </div>

            {/* Banner */}
            <div style={{background:'linear-gradient(135deg,rgba(255,215,0,0.1),rgba(0,22,40,0.9))',border:`1px solid rgba(255,215,0,0.25)`,borderRadius:20,padding:'20px',marginBottom:24,position:'relative',overflow:'hidden'}}>
              <div style={{position:'absolute',right:16,top:'50%',transform:'translateY(-50%)',opacity:.08}}>
                <svg width="130" height="110" viewBox="0 0 130 110" fill="none">
                  <rect x="15" y="10" width="100" height="90" rx="6" stroke="#FFD700" strokeWidth="1.5" fill="none"/>
                  <path d="M15 28h100" stroke="#FFD700" strokeWidth="1"/>
                  <rect x="25" y="38" width="80" height="6" rx="3" fill="#FFD700" opacity=".4"/>
                  <rect x="25" y="50" width="60" height="6" rx="3" fill="#FFD700" opacity=".3"/>
                  <rect x="25" y="62" width="70" height="6" rx="3" fill="#FFD700" opacity=".3"/>
                  <rect x="25" y="74" width="50" height="6" rx="3" fill="#FFD700" opacity=".2"/>
                  <circle cx="20" cy="19" r="4" fill="#FFD700" opacity=".6"/>
                  <circle cx="105" cy="100" r="5" fill="#4D9FFF" opacity=".5"/>
                </svg>
              </div>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:C.gold,marginBottom:4}}>{lang==='en'?'10 Years of NEET Questions':'10 साल के NEET प्रश्न'}</div>
              <div style={{fontSize:12,color:C.sub,marginBottom:16,maxWidth:500}}>{lang==='en'?'Access all NEET PYQs from 2015 to 2024. Most repeated topics are highlighted for focused revision.':'2015 से 2024 तक सभी NEET PYQ देखें। सबसे ज्यादा दोहराए जाने वाले विषय हाइलाइट हैं।'}</div>
              <div style={{display:'flex',gap:12,flexWrap:'wrap'}}>
                {[[stats.total,lang==='en'?'Total Questions':'कुल प्रश्न',C.primary],[stats.physics,lang==='en'?'Physics':'भौतिकी','#00B4FF'],[stats.chemistry,lang==='en'?'Chemistry':'रसायन','#FF6B9D'],[stats.biology,lang==='en'?'Biology':'जीव विज्ञान','#00E5A0']].map(([v,l,c])=>(
                  <div key={String(l)} style={{textAlign:'center',padding:'10px 16px',background:`${c}15`,border:`1px solid ${c}30`,borderRadius:10}}>
                    <div style={{fontWeight:800,fontSize:18,color:String(c)}}>{v}</div>
                    <div style={{fontSize:10,color:C.sub,marginTop:2}}>{l}</div>
                  </div>
                ))}
              </div>
            </div>

            {/* Year Cards */}
            <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(110px,1fr))',gap:10,marginBottom:20}}>
              {years.map(y=>(
                <button key={y} onClick={()=>{setYear(y);}} style={{padding:'14px 10px',background:year===y?`linear-gradient(135deg,${C.primary},#0055CC)`:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${year===y?C.primary:C.border}`,borderRadius:12,cursor:'pointer',textAlign:'center',transition:'all .2s'}}>
                  <div style={{fontWeight:700,color:year===y?'#fff':C.primary,fontSize:14}}>NEET {y}</div>
                  <div style={{fontSize:10,color:year===y?'rgba(255,255,255,0.7)':C.sub,marginTop:2}}>180 Qs</div>
                </button>
              ))}
            </div>

            {/* Filters */}
            <div style={{display:'flex',gap:10,marginBottom:16,flexWrap:'wrap'}}>
              <select value={year} onChange={e=>setYear(e.target.value)} style={{padding:'10px 14px',background:'rgba(0,22,40,0.85)',border:`1.5px solid rgba(77,159,255,0.3)`,borderRadius:10,color:C.text,fontSize:13,fontFamily:'Inter,sans-serif',outline:'none'}}>
                <option value="all">{lang==='en'?'All Years':'सभी वर्ष'}</option>
                {years.map(y=><option key={y} value={y}>NEET {y}</option>)}
              </select>
              <select value={subject} onChange={e=>setSubject(e.target.value)} style={{padding:'10px 14px',background:'rgba(0,22,40,0.85)',border:`1.5px solid rgba(77,159,255,0.3)`,borderRadius:10,color:C.text,fontSize:13,fontFamily:'Inter,sans-serif',outline:'none'}}>
                <option value="all">{lang==='en'?'All Subjects':'सभी विषय'}</option>
                <option value="Physics">{lang==='en'?'⚛️ Physics':'⚛️ भौतिकी'}</option>
                <option value="Chemistry">{lang==='en'?'🧪 Chemistry':'🧪 रसायन'}</option>
                <option value="Biology">{lang==='en'?'🧬 Biology':'🧬 जीव विज्ञान'}</option>
              </select>
              <button onClick={loadPYQ} disabled={loading} className="btn-p" style={{opacity:loading?.7:1}}>
                {loading?'⟳ Loading...':lang==='en'?'🔍 Load Questions':'🔍 प्रश्न लोड करें'}
              </button>
            </div>

            {/* Questions */}
            {questions.length>0?(
              <div>
                <div style={{fontSize:12,color:C.sub,marginBottom:10}}>{questions.length} {lang==='en'?'questions found':'प्रश्न मिले'}</div>
                {questions.slice(0,15).map((q:any,i:number)=>(
                  <div key={q._id||i} style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:12,padding:16,marginBottom:10,backdropFilter:'blur(12px)'}}>
                    <div style={{display:'flex',gap:8,flexWrap:'wrap',marginBottom:8}}>
                      {q.year&&<span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:`${C.gold}15`,color:C.gold,border:`1px solid ${C.gold}30`,fontWeight:600}}>NEET {q.year}</span>}
                      {q.subject&&<span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:`${C.primary}15`,color:C.primary,border:`1px solid ${C.primary}30`,fontWeight:600}}>{q.subject}</span>}
                      {q.difficulty&&<span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:'rgba(255,255,255,0.1)',color:C.sub,border:`1px solid ${C.border}`,fontWeight:600}}>{q.difficulty}</span>}
                    </div>
                    <div style={{fontSize:13,color:dm?C.text:'#0F172A',lineHeight:1.6,marginBottom:8}}><strong>Q{i+1}.</strong> {q.text||q.question||'—'}</div>
                    {q.options&&Array.isArray(q.options)&&(
                      <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:6,marginTop:8}}>
                        {q.options.map((opt:string,j:number)=>(
                          <div key={j} style={{padding:'6px 10px',background:'rgba(77,159,255,0.06)',border:`1px solid ${C.border}`,borderRadius:8,fontSize:12,color:C.sub}}>
                            <span style={{color:C.primary,fontWeight:700,marginRight:6}}>{String.fromCharCode(65+j)}.</span>{opt}
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            ):(
              <div style={{textAlign:'center',padding:'50px 20px',background:dm?C.card:'rgba(255,255,255,0.85)',borderRadius:20,border:`1px solid ${C.border}`}}>
                <svg width="70" height="70" viewBox="0 0 70 70" fill="none" style={{display:'block',margin:'0 auto 14px'}}>
                  <rect x="10" y="8" width="50" height="54" rx="5" stroke="#FFD700" strokeWidth="1.5" fill="none"/>
                  <path d="M20 22h30M20 32h20M20 42h25" stroke="#FFD700" strokeWidth="1.5" strokeLinecap="round"/>
                  <circle cx="55" cy="55" r="12" fill="rgba(77,159,255,0.15)" stroke="#4D9FFF" strokeWidth="1.5"/>
                  <path d="M51 55 L54 58 L59 52" stroke="#4D9FFF" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
                <div style={{fontSize:15,fontWeight:700,color:dm?C.text:'#0F172A',marginBottom:6}}>{lang==='en'?'Select year & subject, then click Load':'वर्ष और विषय चुनें, फिर लोड करें'}</div>
                <div style={{fontSize:12,color:C.sub}}>{lang==='en'?'10 years of NEET questions available':'10 साल के NEET प्रश्न उपलब्ध'}</div>
              </div>
            )}
          </div>
        )
      }}
    </StudentShell>
  )
}
