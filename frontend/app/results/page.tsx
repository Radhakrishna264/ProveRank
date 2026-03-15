'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

function GraphSVG() {
  return (
    <svg width="80" height="70" viewBox="0 0 80 70" fill="none" style={{animation:'float 4s ease-in-out infinite',flexShrink:0}}>
      <path d="M5 60 L5 10 L75 10" stroke="#4D9FFF" strokeWidth="1.5" strokeLinecap="round"/>
      <path d="M5 55 L20 40 L32 45 L48 25 L62 30 L75 15" stroke="#4D9FFF" strokeWidth="2" strokeLinecap="round" fill="none"/>
      <path d="M5 55 L20 40 L32 45 L48 25 L62 30 L75 15 L75 60 L5 60Z" fill="rgba(77,159,255,0.12)"/>
      <circle cx="20" cy="40" r="4" fill="#4D9FFF"/>
      <circle cx="48" cy="25" r="4" fill="#FFD700"/>
      <circle cx="75" cy="15" r="4" fill="#00C48C"/>
    </svg>
  )
}

function ResultsContent() {
  const {lang,darkMode:dm,user,toast,token}=useShell()
  const [results,setResults]=useState<any[]>([])
  const [loading,setLoading]=useState(true)
  const [selId,  setSelId]  =useState('')
  const t=(en:string,hi:string)=>lang==='en'?en:hi

  useEffect(()=>{
    if(!token) return
    fetch(`${API}/api/results`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{setResults(Array.isArray(d)?d:[]);setLoading(false)}).catch(()=>setLoading(false))
  },[token])

  const best =results.length?Math.max(...results.map((r:any)=>r.score||0)):null
  const avg  =results.length?Math.round(results.reduce((a,r:any)=>a+(r.score||0),0)/results.length):null
  const bRank=results.length?Math.min(...results.map((r:any)=>r.rank||99999)):null

  const share=(r:any)=>{
    const txt=`🎯 I scored ${r.score}/${r.totalMarks||720} in ${r.examTitle||'NEET Mock'}!\n🏆 AIR #${r.rank||'—'} · ${r.percentile||'—'}%ile\n📊 ProveRank — prove-rank.vercel.app`
    if(navigator.share) navigator.share({title:'My ProveRank Result',text:txt}).catch(()=>{})
    else{navigator.clipboard?.writeText(txt);toast(t('Copied to clipboard!','क्लिपबोर्ड पर कॉपी!'),'s')}
  }

  const dlReceipt=async(r:any)=>{
    try{
      const res=await fetch(`${API}/api/results/${r._id}/receipt`,{headers:{Authorization:`Bearer ${token}`}})
      if(res.ok){const b=await res.blob();const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download=`receipt_${r.examTitle||'exam'}.pdf`;a.click();toast(t('Receipt downloaded! (N2)','रसीद डाउनलोड हुई!'),'s')}
      else toast(t('Receipt not available yet','रसीद अभी उपलब्ध नहीं'),'w')
    }catch{toast('Network error','e')}
  }

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:18,flexWrap:'wrap',gap:10}}>
        <div>
          <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>📈 {t('My Results','मेरे परिणाम')}</h1>
          <div style={{fontSize:13,color:C.sub}}>{t('All exam results & performance — your story in numbers','सभी परीक्षा परिणाम और प्रदर्शन')}</div>
        </div>
        {results.length>0&&(
          <button onClick={()=>{fetch(`${API}/api/results/export`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>{if(r.ok)return r.blob()}).then(b=>{if(b){const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download='results.csv';a.click();toast(t('Exported!','निर्यात हुआ!'),'s')}}).catch(()=>toast('Not available','w'))}} className="btn-g">📥 {t('Export CSV','CSV निर्यात')}</button>
        )}
      </div>

      {/* Quote + Graph */}
      <div style={{background:'linear-gradient(135deg,rgba(255,215,0,.08),rgba(0,22,40,.88))',border:'1px solid rgba(255,215,0,.18)',borderRadius:20,padding:20,marginBottom:22,display:'flex',alignItems:'center',gap:16,position:'relative',overflow:'hidden',flexWrap:'wrap'}}>
        <GraphSVG/>
        <div style={{flex:1}}>
          <div style={{fontSize:14,color:C.gold,fontStyle:'italic',fontWeight:700,marginBottom:4}}>{t('"Your score today is just the beginning — your potential is limitless."','"आज का स्कोर बस शुरुआत है — आपकी क्षमता असीमित है।"')}</div>
          <div style={{fontSize:11,color:C.sub}}>{results.length>0?(results.length+' '+t('exam results recorded','परीक्षा परिणाम दर्ज')):t('Give your first exam to see results!','पहली परीक्षा दें!')}</div>
        </div>
      </div>

      {/* Stats */}
      <div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:20}}>
        {[[results.length,t('Tests Taken','दिए टेस्ट'),'📝',C.primary],[best?`${best}/720`:'—',t('Best Score','सर्वश्रेष्ठ'),'🏆',C.gold],[avg?`${avg}/720`:'—',t('Avg Score','औसत'),'📊',C.success],[bRank&&bRank<99999?`#${bRank}`:'—',t('Best Rank','सर्वश्रेष्ठ रैंक'),'🥇',C.purple||'#A78BFA']].map(([v,l,ic,col])=>(
          <div key={String(l)} className="card-h" style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:14,padding:'14px 16px',flex:1,minWidth:110,backdropFilter:'blur(14px)',textAlign:'center',transition:'all .25s',boxShadow:'0 2px 12px rgba(0,0,0,.15)'}}>
            <div style={{fontSize:22,marginBottom:5}}>{ic}</div>
            <div style={{fontSize:22,fontWeight:800,color:String(col),fontFamily:'Playfair Display,serif',textShadow:`0 0 12px ${col}44`}}>{v}</div>
            <div style={{fontSize:10,color:C.sub,marginTop:3}}>{l}</div>
          </div>
        ))}
      </div>

      {/* Score trend */}
      {results.length>1&&(
        <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:18,marginBottom:18,backdropFilter:'blur(14px)',boxShadow:'0 2px 16px rgba(0,0,0,.15)'}}>
          <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:dm?C.text:C.textL,marginBottom:14}}>📈 {t('Score Trend','स्कोर ट्रेंड')}</div>
          <div style={{display:'flex',alignItems:'flex-end',gap:6,height:80}}>
            {results.slice(0,6).reverse().map((r:any,i:number)=>{
              const h=Math.round(((r.score||0)/720)*100)
              const col=h>80?C.success:h>60?C.primary:h>40?C.warn:C.danger
              return (
                <div key={i} style={{flex:1,display:'flex',flexDirection:'column',alignItems:'center',gap:3}}>
                  <div style={{fontSize:9,color:col,fontWeight:700}}>{r.score}</div>
                  <div style={{width:'100%',height:`${h}%`,background:`linear-gradient(180deg,${col},${col}55)`,borderRadius:'4px 4px 0 0',minHeight:3,transition:'height .8s ease'}}/>
                  <div style={{fontSize:7,color:C.sub}}>{r.submittedAt?new Date(r.submittedAt).toLocaleDateString('en-IN',{month:'short',day:'numeric'}):`T${i+1}`}</div>
                </div>
              )
            })}
          </div>
        </div>
      )}

      {/* Results list */}
      <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,overflow:'hidden',backdropFilter:'blur(14px)',marginBottom:18,boxShadow:'0 2px 16px rgba(0,0,0,.15)'}}>
        <div style={{padding:'14px 20px',borderBottom:`1px solid ${C.border}`,fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:dm?C.text:C.textL}}>📋 {t('All Results','सभी परिणाम')}</div>
        {loading?<div style={{textAlign:'center',padding:'40px',color:C.sub,animation:'pulse 1.5s infinite'}}>⟳ Loading...</div>:
          results.length===0?(
            <div style={{textAlign:'center',padding:'60px 20px',color:C.sub}}>
              <svg width="70" height="70" viewBox="0 0 70 70" style={{display:'block',margin:'0 auto 14px'}} fill="none">
                <circle cx="35" cy="35" r="30" stroke="#FFD700" strokeWidth="1.5" strokeDasharray="5 4"/>
                <path d="M35 15L39 27H52L42 34L46 46L35 39L24 46L28 34L18 27H31Z" stroke="#FFD700" strokeWidth="1.5" fill="none"/>
              </svg>
              <div style={{fontWeight:700,fontSize:15,marginBottom:6}}>{t('No results yet','अभी कोई परिणाम नहीं')}</div>
              <div style={{fontSize:12,marginBottom:16}}>{t('Give your first exam to see results here!','पहली परीक्षा दें!')}</div>
              <a href="/my-exams" className="btn-p" style={{textDecoration:'none',display:'inline-block'}}>{t('Start a Test Now →','अभी टेस्ट शुरू करें →')}</a>
            </div>
          ):results.map((r:any)=>(
            <div key={r._id} style={{padding:'14px 20px',borderBottom:`1px solid ${C.border}`}}>
              <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',flexWrap:'wrap',gap:10}}>
                <div style={{flex:1,minWidth:180}}>
                  <div style={{fontWeight:700,fontSize:14,color:dm?C.text:C.textL,marginBottom:3}}>{r.examTitle||r.exam?.title||'—'}</div>
                  <div style={{fontSize:11,color:C.sub}}>{r.submittedAt?new Date(r.submittedAt).toLocaleDateString('en-IN',{day:'numeric',month:'short',year:'numeric'}):''}</div>
                  {r.subjectScores&&(
                    <div style={{display:'flex',gap:7,marginTop:5,flexWrap:'wrap'}}>
                      {r.subjectScores.physics!=null&&<span style={{fontSize:9,padding:'1px 7px',borderRadius:20,background:'rgba(0,180,255,.15)',color:'#00B4FF'}}>⚛️ {r.subjectScores.physics}/180</span>}
                      {r.subjectScores.chemistry!=null&&<span style={{fontSize:9,padding:'1px 7px',borderRadius:20,background:'rgba(255,107,157,.15)',color:'#FF6B9D'}}>🧪 {r.subjectScores.chemistry}/180</span>}
                      {r.subjectScores.biology!=null&&<span style={{fontSize:9,padding:'1px 7px',borderRadius:20,background:'rgba(0,229,160,.15)',color:'#00E5A0'}}>🧬 {r.subjectScores.biology}/360</span>}
                    </div>
                  )}
                </div>
                <div style={{display:'flex',gap:12,alignItems:'center',flexWrap:'wrap'}}>
                  <div style={{textAlign:'center'}}>
                    <div style={{fontWeight:800,fontSize:22,color:C.primary,fontFamily:'Playfair Display,serif',textShadow:`0 0 10px ${C.primary}44`}}>{r.score}</div>
                    <div style={{fontSize:9,color:C.sub}}>/{r.totalMarks||720}</div>
                  </div>
                  <div style={{textAlign:'center'}}>
                    <div style={{fontWeight:700,fontSize:16,color:C.gold}}>#{r.rank||'—'}</div>
                    <div style={{fontSize:9,color:C.sub}}>AIR</div>
                  </div>
                  <div style={{textAlign:'center'}}>
                    <div style={{fontWeight:700,fontSize:14,color:C.success}}>{r.percentile||'—'}%</div>
                    <div style={{fontSize:9,color:C.sub}}>ile</div>
                  </div>
                  <div style={{display:'flex',gap:5,flexWrap:'wrap'}}>
                    <button onClick={()=>setSelId(selId===r._id?'':r._id)} className="btn-g" style={{fontSize:10,padding:'5px 10px'}}>{t('Details','विवरण')}</button>
                    <button onClick={()=>share(r)} style={{padding:'5px 10px',background:'rgba(0,196,140,.12)',color:C.success,border:'1px solid rgba(0,196,140,.3)',borderRadius:8,cursor:'pointer',fontSize:10,fontFamily:'Inter,sans-serif',fontWeight:600}}>📤</button>
                    <button onClick={()=>dlReceipt(r)} style={{padding:'5px 10px',background:`${C.gold}15`,color:C.gold,border:`1px solid ${C.gold}30`,borderRadius:8,cursor:'pointer',fontSize:10,fontFamily:'Inter,sans-serif',fontWeight:600}} title="N2 Receipt">📄</button>
                  </div>
                </div>
              </div>
              {selId===r._id&&(
                <div style={{marginTop:12,padding:14,background:'rgba(77,159,255,.06)',borderRadius:11,border:`1px solid ${C.border}`}}>
                  <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(110px,1fr))',gap:8}}>
                    {[['✅ Correct',r.correct||'—',C.success],['❌ Wrong',r.wrong||'—',C.danger],['⭕ Skipped',r.unattempted||'—',C.sub],['🎯 Accuracy',r.accuracy?`${r.accuracy}%`:'—',C.primary]].map(([l,v,c])=>(
                      <div key={String(l)} style={{background:'rgba(0,22,40,.5)',borderRadius:9,padding:'10px',textAlign:'center',border:`1px solid ${C.border}`}}>
                        <div style={{fontWeight:700,fontSize:16,color:String(c)}}>{v}</div>
                        <div style={{fontSize:9,color:C.sub,marginTop:2}}>{l}</div>
                      </div>
                    ))}
                  </div>
                  <div style={{display:'flex',gap:7,marginTop:10,flexWrap:'wrap'}}>
                    <a href={`/exam-review/${r._id}`} className="btn-g" style={{fontSize:10,textDecoration:'none'}}>🔍 {t('Review Mode (S29)','समीक्षा मोड')}</a>
                    <a href="/omr-view" className="btn-g" style={{fontSize:10,textDecoration:'none'}}>📋 OMR (S102)</a>
                  </div>
                </div>
              )}
            </div>
          ))
        }
      </div>
    </div>
  )
}

export default function ResultsPage() {
  return <StudentShell pageKey="results"><ResultsContent/></StudentShell>
}
