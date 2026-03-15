'use client'
import { useState } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

function PYQContent() {
  const { lang, darkMode:dm, toast, token } = useShell()
  const [year,  setYear]  = useState('all')
  const [subj,  setSubj]  = useState('all')
  const [qs,    setQs]    = useState<any[]>([])
  const [loading,setLoad] = useState(false)
  const t = (en:string, hi:string) => lang==='en' ? en : hi
  const years = ['2024','2023','2022','2021','2020','2019','2018','2017','2016','2015']

  const load = async () => {
    if(!token) return; setLoad(true)
    try {
      const p=new URLSearchParams(); if(year!=='all')p.set('year',year); if(subj!=='all')p.set('subject',subj)
      const r=await fetch(`${API}/api/questions/pyq?${p}`,{headers:{Authorization:`Bearer ${token}`}})
      if(r.ok){const d=await r.json();setQs(Array.isArray(d)?d:(d.questions||[]))}
      else toast(t('PYQ data not available','PYQ डेटा उपलब्ध नहीं'),'w')
    } catch { toast('Network error','e') }
    setLoad(false)
  }

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.gold},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>📚 {t('PYQ Bank','पिछले वर्ष के प्रश्न')} (S104)</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('NEET Previous Year Questions 2015–2024','NEET 2015-2024 के पिछले वर्ष के प्रश्न')}</div>

      <div style={{background:'linear-gradient(135deg,rgba(255,215,0,.1),rgba(0,22,40,.9))',border:'1px solid rgba(255,215,0,.22)',borderRadius:18,padding:18,marginBottom:22}}>
        <div style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:C.gold,marginBottom:4}}>{t('10 Years of NEET Questions','10 साल के NEET प्रश्न')}</div>
        <div style={{fontSize:12,color:C.sub,marginBottom:14}}>{t('Access all NEET PYQs. Most repeated topics highlighted for focused revision.','सभी NEET PYQ देखें। सबसे ज्यादा दोहराए विषय हाइलाइट।')}</div>
        <div style={{display:'flex',gap:10,flexWrap:'wrap'}}>
          {[['1800',t('Total Qs','कुल प्रश्न'),C.primary],['450','Physics','#00B4FF'],['450','Chemistry','#FF6B9D'],['900','Biology','#00E5A0']].map(([v,l,c])=>(
            <div key={String(l)} style={{textAlign:'center',padding:'8px 14px',background:`${c}15`,border:`1px solid ${c}30`,borderRadius:9}}>
              <div style={{fontWeight:800,fontSize:17,color:c}}>{v}</div><div style={{fontSize:9,color:C.sub,marginTop:1}}>{l}</div>
            </div>
          ))}
        </div>
      </div>

      <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(100px,1fr))',gap:8,marginBottom:18}}>
        {years.map(y=>(
          <button key={y} onClick={()=>setYear(y)} style={{padding:'12px 8px',background:year===y?`linear-gradient(135deg,${C.primary},#0055CC)`:dm?C.card:C.cardL,border:`1px solid ${year===y?C.primary:C.border}`,borderRadius:11,cursor:'pointer',textAlign:'center',transition:'all .2s'}}>
            <div style={{fontWeight:700,color:year===y?'#fff':C.primary,fontSize:13}}>NEET {y}</div>
            <div style={{fontSize:9,color:year===y?'rgba(255,255,255,.7)':C.sub,marginTop:1}}>180 Qs</div>
          </button>
        ))}
      </div>

      <div style={{display:'flex',gap:9,marginBottom:16,flexWrap:'wrap'}}>
        <select value={year} onChange={e=>setYear(e.target.value)} style={{padding:'10px 12px',background:'rgba(0,22,40,.85)',border:'1.5px solid rgba(77,159,255,.3)',borderRadius:9,color:C.text,fontSize:13,fontFamily:'Inter,sans-serif',outline:'none'}}>
          <option value="all">{t('All Years','सभी वर्ष')}</option>
          {years.map(y=><option key={y} value={y}>NEET {y}</option>)}
        </select>
        <select value={subj} onChange={e=>setSubj(e.target.value)} style={{padding:'10px 12px',background:'rgba(0,22,40,.85)',border:'1.5px solid rgba(77,159,255,.3)',borderRadius:9,color:C.text,fontSize:13,fontFamily:'Inter,sans-serif',outline:'none'}}>
          <option value="all">{t('All Subjects','सभी विषय')}</option>
          <option value="Physics">{t('⚛️ Physics','⚛️ भौतिकी')}</option>
          <option value="Chemistry">{t('🧪 Chemistry','🧪 रसायन')}</option>
          <option value="Biology">{t('🧬 Biology','🧬 जीव विज्ञान')}</option>
        </select>
        <button onClick={load} disabled={loading} className="btn-p" style={{opacity:loading?.7:1}}>{loading?'⟳ Loading...':t('🔍 Load Questions','🔍 प्रश्न लोड करें')}</button>
      </div>

      {qs.length>0 ? (
        <div>
          <div style={{fontSize:12,color:C.sub,marginBottom:10}}>{qs.length} {t('questions found','प्रश्न मिले')}</div>
          {qs.slice(0,15).map((q:any,i:number)=>(
            <div key={q._id||i} style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:11,padding:15,marginBottom:9,backdropFilter:'blur(12px)'}}>
              <div style={{display:'flex',gap:7,flexWrap:'wrap',marginBottom:7}}>
                {q.year&&<span style={{fontSize:9,padding:'1px 7px',borderRadius:20,background:`${C.gold}15`,color:C.gold,fontWeight:600}}>NEET {q.year}</span>}
                {q.subject&&<span style={{fontSize:9,padding:'1px 7px',borderRadius:20,background:`${C.primary}15`,color:C.primary,fontWeight:600}}>{q.subject}</span>}
                {q.difficulty&&<span style={{fontSize:9,padding:'1px 7px',borderRadius:20,background:'rgba(255,255,255,.08)',color:C.sub}}>{q.difficulty}</span>}
              </div>
              <div style={{fontSize:13,color:dm?C.text:C.textL,lineHeight:1.6}}><strong>Q{i+1}.</strong> {q.text||q.question||'—'}</div>
              {q.options&&Array.isArray(q.options)&&(
                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:5,marginTop:8}}>
                  {q.options.map((o:string,j:number)=>(
                    <div key={j} style={{padding:'5px 9px',background:'rgba(77,159,255,.06)',border:`1px solid ${C.border}`,borderRadius:7,fontSize:11,color:C.sub}}>
                      <span style={{color:C.primary,fontWeight:700,marginRight:5}}>{String.fromCharCode(65+j)}.</span>{o}
                    </div>
                  ))}
                </div>
              )}
            </div>
          ))}
        </div>
      ) : (
        <div style={{textAlign:'center',padding:'50px 20px',background:dm?C.card:C.cardL,borderRadius:18,border:`1px solid ${C.border}`}}>
          <div style={{fontSize:42,marginBottom:12}}>📚</div>
          <div style={{fontSize:15,fontWeight:700,color:dm?C.text:C.textL,marginBottom:6}}>{t('Select year & subject, then click Load','वर्ष और विषय चुनें, फिर लोड करें')}</div>
          <div style={{fontSize:12,color:C.sub}}>{t('10 years of NEET questions available','10 साल के NEET प्रश्न उपलब्ध')}</div>
        </div>
      )}
    </div>
  )
}

export default function PYQBankPage() {
  return <StudentShell pageKey="pyq-bank"><PYQContent/></StudentShell>
}
