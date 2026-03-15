'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

function ResultsContent() {
  const { lang, darkMode:dm, user, toast, token } = useShell()
  const [results, setResults] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [selId,   setSelId]   = useState('')
  const t = (en:string, hi:string) => lang==='en' ? en : hi

  useEffect(()=>{
    if(!token) return
    fetch(`${API}/api/results`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{setResults(Array.isArray(d)?d:[]);setLoading(false)}).catch(()=>setLoading(false))
  },[token])

  const best  = results.length ? Math.max(...results.map((r:any)=>r.score||0)) : null
  const avg   = results.length ? Math.round(results.reduce((a,r:any)=>a+(r.score||0),0)/results.length) : null
  const bRank = results.length ? Math.min(...results.map((r:any)=>r.rank||99999)) : null

  const share = (r:any) => {
    const txt = `🎯 I scored ${r.score}/${r.totalMarks||720} in ${r.examTitle||'NEET Mock'}!\n🏆 AIR #${r.rank||'—'} · ${r.percentile||'—'}%ile\n📊 ProveRank — prove-rank.vercel.app`
    if(navigator.share) navigator.share({title:'My ProveRank Result',text:txt}).catch(()=>{})
    else { navigator.clipboard?.writeText(txt); toast(t('Copied to clipboard!','क्लिपबोर्ड पर कॉपी हुआ!'),'s') }
  }

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:18,flexWrap:'wrap',gap:10}}>
        <div>
          <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>📈 {t('My Results','मेरे परिणाम')}</h1>
          <div style={{fontSize:13,color:C.sub}}>{t('All exam results & performance','सभी परीक्षा परिणाम और प्रदर्शन')}</div>
        </div>
        {results.length>0 && (
          <button onClick={()=>{
            fetch(`${API}/api/results/export`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>{if(r.ok)return r.blob()}).then(b=>{if(b){const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download='results.csv';a.click();toast(t('Downloaded!','डाउनलोड हुआ!'),'s')}}).catch(()=>toast('Export failed','w'))
          }} className="btn-g">📥 {t('Export CSV','CSV निर्यात')}</button>
        )}
      </div>

      {/* Quote */}
      <div style={{background:'linear-gradient(135deg,rgba(255,215,0,.08),rgba(0,22,40,.85))',border:'1px solid rgba(255,215,0,.18)',borderRadius:18,padding:18,marginBottom:22,display:'flex',alignItems:'center',gap:14,position:'relative',overflow:'hidden'}}>
        <div style={{position:'absolute',right:14,opacity:.08}}><svg width="100" height="80" viewBox="0 0 100 80" fill="none"><path d="M50 5 L60 32 L90 32 L67 50 L76 77 L50 60 L24 77 L33 50 L10 32 L40 32 Z" stroke="#FFD700" strokeWidth="1.5" fill="none"/></svg></div>
        <span style={{fontSize:28}}>🏆</span>
        <div style={{fontSize:13,color:C.gold,fontStyle:'italic',fontWeight:600}}>{t('"Your score today is just the beginning — your potential is limitless."','"आज का स्कोर बस शुरुआत है — आपकी क्षमता असीमित है।"')}</div>
      </div>

      {/* Stats */}
      <div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:22}}>
        {[[results.length,t('Tests Taken','दिए टेस्ट'),'📝',C.primary],[best?`${best}/720`:'—',t('Best Score','सर्वश्रेष्ठ स्कोर'),'🏆',C.gold],[avg?`${avg}/720`:'—',t('Avg Score','औसत स्कोर'),'📊',C.success],[bRank&&bRank<99999?`#${bRank}`:'—',t('Best Rank','सर्वश्रेष्ठ रैंक'),'🥇',C.purple||'#A78BFA']].map(([v,l,ic,col])=>(
          <div key={String(l)} className="card-h" style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:14,padding:'14px 18px',flex:1,minWidth:110,backdropFilter:'blur(12px)',textAlign:'center',transition:'all .2s'}}>
            <div style={{fontSize:20,marginBottom:5}}>{ic}</div>
            <div style={{fontSize:22,fontWeight:800,color:String(col),fontFamily:'Playfair Display,serif'}}>{v}</div>
            <div style={{fontSize:10,color:C.sub,marginTop:3}}>{l}</div>
          </div>
        ))}
      </div>

      {/* Score Trend */}
      {results.length>1 && (
        <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:18,marginBottom:18,backdropFilter:'blur(12px)'}}>
          <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:C.textL,marginBottom:14}}>📈 {t('Score Trend (Last 5 Tests)','स्कोर ट्रेंड (पिछले 5 टेस्ट)')}</div>
          <div style={{display:'flex',alignItems:'flex-end',gap:6,height:80}}>
            {results.slice(0,5).reverse().map((r:any,i:number)=>{
              const h=Math.round(((r.score||0)/720)*100)
              const col=h>80?C.success:h>60?C.primary:h>40?C.warn:C.danger
              return (
                <div key={i} style={{flex:1,display:'flex',flexDirection:'column',alignItems:'center',gap:3}}>
                  <div style={{fontSize:9,color:col,fontWeight:700}}>{r.score}</div>
                  <div style={{width:'100%',height:`${h}%`,background:`linear-gradient(180deg,${col},${col}55)`,borderRadius:'4px 4px 0 0',minHeight:3,transition:'height .6s ease'}}/>
                  <div style={{fontSize:8,color:C.sub,textAlign:'center'}}>{r.submittedAt?new Date(r.submittedAt).toLocaleDateString('en-IN',{month:'short',day:'numeric'}):`T${i+1}`}</div>
                </div>
              )
            })}
          </div>
        </div>
      )}

      {/* Results List */}
      <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,overflow:'hidden',backdropFilter:'blur(12px)',marginBottom:18}}>
        <div style={{padding:'14px 18px',borderBottom:`1px solid ${C.border}`,fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:C.textL}}>📋 {t('All Results','सभी परिणाम')}</div>
        {loading ? <div style={{textAlign:'center',padding:'40px',color:C.sub}}>⟳ Loading...</div> :
          results.length===0 ? (
            <div style={{textAlign:'center',padding:'50px 20px',color:C.sub}}>
              <div style={{fontSize:42,marginBottom:12}}>⭐</div>
              <div style={{fontWeight:700,fontSize:15,marginBottom:6}}>{t('No results yet','अभी कोई परिणाम नहीं')}</div>
              <div style={{fontSize:12,marginBottom:16}}>{t('Give your first exam to see results!','यहां परिणाम देखने के लिए पहली परीक्षा दें!')}</div>
              <a href="/my-exams" className="btn-p" style={{textDecoration:'none',display:'inline-block'}}>{t('Start a Test Now →','अभी टेस्ट शुरू करें →')}</a>
            </div>
          ) : results.map((r:any)=>(
            <div key={r._id} style={{padding:'14px 18px',borderBottom:`1px solid ${C.border}`}}>
              <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',flexWrap:'wrap',gap:10}}>
                <div style={{flex:1,minWidth:180}}>
                  <div style={{fontWeight:700,fontSize:14,color:dm?C.text:C.textL,marginBottom:3}}>{r.examTitle||r.exam?.title||'—'}</div>
                  <div style={{fontSize:11,color:C.sub}}>{r.submittedAt?new Date(r.submittedAt).toLocaleDateString('en-IN',{day:'numeric',month:'short',year:'numeric'}):''}</div>
                  {r.subjectScores && (
                    <div style={{display:'flex',gap:8,marginTop:5,flexWrap:'wrap'}}>
                      {r.subjectScores.physics!==undefined&&<span style={{fontSize:9,padding:'1px 6px',borderRadius:20,background:'rgba(0,180,255,.15)',color:'#00B4FF'}}>⚛️ {r.subjectScores.physics}/180</span>}
                      {r.subjectScores.chemistry!==undefined&&<span style={{fontSize:9,padding:'1px 6px',borderRadius:20,background:'rgba(255,107,157,.15)',color:'#FF6B9D'}}>🧪 {r.subjectScores.chemistry}/180</span>}
                      {r.subjectScores.biology!==undefined&&<span style={{fontSize:9,padding:'1px 6px',borderRadius:20,background:'rgba(0,229,160,.15)',color:'#00E5A0'}}>🧬 {r.subjectScores.biology}/360</span>}
                    </div>
                  )}
                </div>
                <div style={{display:'flex',gap:14,alignItems:'center',flexWrap:'wrap'}}>
                  <div style={{textAlign:'center'}}>
                    <div style={{fontWeight:800,fontSize:22,color:C.primary,fontFamily:'Playfair Display,serif'}}>{r.score}</div>
                    <div style={{fontSize:9,color:C.sub}}>/{r.totalMarks||720}</div>
                  </div>
                  <div style={{textAlign:'center'}}>
                    <div style={{fontWeight:700,fontSize:16,color:C.gold}}>#{r.rank||'—'}</div>
                    <div style={{fontSize:9,color:C.sub}}>AIR</div>
                  </div>
                  <div style={{textAlign:'center'}}>
                    <div style={{fontWeight:700,fontSize:15,color:C.success}}>{r.percentile||'—'}%</div>
                    <div style={{fontSize:9,color:C.sub}}>ile</div>
                  </div>
                  <div style={{display:'flex',gap:6,flexWrap:'wrap'}}>
                    <button onClick={()=>setSelId(selId===r._id?'':r._id)} className="btn-g" style={{fontSize:11,padding:'6px 12px'}}>{t('Details','विवरण')}</button>
                    <button onClick={()=>share(r)} style={{padding:'6px 12px',background:'rgba(0,196,140,.12)',color:C.success,border:'1px solid rgba(0,196,140,.3)',borderRadius:8,cursor:'pointer',fontSize:11,fontFamily:'Inter,sans-serif',fontWeight:600}}>📤 {t('Share','शेयर')}</button>
                    <button onClick={()=>{ fetch(`${API}/api/results/${r._id}/receipt`,{headers:{Authorization:`Bearer ${token}`}}).then(res=>res.ok?res.blob():null).then(b=>{if(b){const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download='receipt.pdf';a.click();toast(t('Receipt downloaded!','रसीद डाउनलोड हुई!'),'s')}else toast(t('Receipt not available','रसीद उपलब्ध नहीं'),'w')}).catch(()=>toast('Error','e')) }} style={{padding:'6px 10px',background:'rgba(255,215,0,.1)',color:C.gold,border:'1px solid rgba(255,215,0,.25)',borderRadius:8,cursor:'pointer',fontSize:10,fontFamily:'Inter,sans-serif',fontWeight:600}}>📄 {t('Receipt (N2)','रसीद')}</button>
                  </div>
                </div>
              </div>
              {selId===r._id && (
                <div style={{marginTop:14,padding:14,background:'rgba(77,159,255,.06)',borderRadius:12,border:`1px solid ${C.border}`}}>
                  <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(120px,1fr))',gap:8}}>
                    {[['✅ Correct',r.correct||'—',C.success],['❌ Wrong',r.wrong||'—',C.danger],['⭕ Skipped',r.unattempted||'—',C.sub],['🎯 Accuracy',r.accuracy?`${r.accuracy}%`:'—',C.primary]].map(([l,v,c])=>(
                      <div key={String(l)} style={{background:'rgba(0,22,40,.5)',borderRadius:10,padding:'10px',textAlign:'center',border:`1px solid ${C.border}`}}>
                        <div style={{fontWeight:700,fontSize:16,color:String(c)}}>{v}</div>
                        <div style={{fontSize:10,color:C.sub,marginTop:2}}>{l}</div>
                      </div>
                    ))}
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
