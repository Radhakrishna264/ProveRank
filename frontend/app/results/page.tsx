'use client'
import { useState, useEffect } from 'react'
import StudentShell from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const C = { primary:'#4D9FFF', card:'rgba(0,22,40,0.80)', border:'rgba(77,159,255,0.22)', text:'#E8F4FF', sub:'#6B8FAF', success:'#00C48C', gold:'#FFD700', danger:'#FF4D4D', warn:'#FFB84D' }

const TR = {
  en:{ title:'My Results', sub:'All exam results & performance — your story in numbers',
    testsTaken:'Tests Taken', bestScore:'Best Score', avgScore:'Avg Score', bestRank:'Best Rank',
    allResults:'All Results', score:'SCORE', rank:'RANK', percentile:'%ILE', date:'DATE',
    viewDetails:'View Details →', export:'Export CSV', noResults:'No results yet',
    noResultsSub:'Give your first exam to see results here!', startNow:'Start a Test Now →',
    quote:'"Your score today is just the beginning — your potential is limitless."',
    quoteHi:'आज का स्कोर बस शुरुआत है — आपकी क्षमता असीमित है।',
    analysis:'Performance Analysis', omrView:'OMR View', receipt:'Download Receipt',
    share:'Share Result', physics:'Physics', chemistry:'Chemistry', biology:'Biology',
  },
  hi:{ title:'मेरे परिणाम', sub:'सभी परीक्षा परिणाम और प्रदर्शन — अंकों में आपकी कहानी',
    testsTaken:'दिए गए टेस्ट', bestScore:'सर्वश्रेष्ठ स्कोर', avgScore:'औसत स्कोर', bestRank:'सर्वश्रेष्ठ रैंक',
    allResults:'सभी परिणाम', score:'स्कोर', rank:'रैंक', percentile:'पर्सेंटाइल', date:'तारीख',
    viewDetails:'विवरण देखें →', export:'CSV निर्यात करें', noResults:'अभी कोई परिणाम नहीं',
    noResultsSub:'यहां परिणाम देखने के लिए पहली परीक्षा दें!', startNow:'अभी टेस्ट शुरू करें →',
    quote:'"आज का स्कोर बस शुरुआत है — आपकी क्षमता असीमित है।"',
    quoteHi:'Your score today is just the beginning — your potential is limitless.',
    analysis:'प्रदर्शन विश्लेषण', omrView:'OMR व्यू', receipt:'रसीद डाउनलोड करें',
    share:'परिणाम शेयर करें', physics:'भौतिकी', chemistry:'रसायन', biology:'जीव विज्ञान',
  }
}

export default function ResultsPage() {
  return (
    <StudentShell pageKey="results">
      {({lang, darkMode:dm, user, toast, token}) => {
        const t = TR[lang]
        const [results, setResults] = useState<any[]>([])
        const [loading, setLoading] = useState(true)
        const [selResult, setSelResult] = useState<any>(null)

        useEffect(()=>{
          if(!token) return
          fetch(`${API}/api/results`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{setResults(Array.isArray(d)?d:[]);setLoading(false)}).catch(()=>setLoading(false))
        },[token])

        const bestScore = results.length>0?Math.max(...results.map((r:any)=>r.score||0)):null
        const avgScore = results.length>0?Math.round(results.reduce((a:number,r:any)=>a+(r.score||0),0)/results.length):null
        const bestRank = results.length>0?Math.min(...results.map((r:any)=>r.rank||99999)):null

        const exportCSV = () => {
          if(!token) return
          fetch(`${API}/api/results/export`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>{
            if(r.ok) return r.blob()
            toast('Export not available','w')
          }).then(b=>{if(b){const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download='results.csv';a.click();toast('Downloaded!','s')}})
        }

        const shareResult = (r:any) => {
          const text = `🎯 I scored ${r.score}/${r.totalMarks||720} in ${r.examTitle||'NEET Mock'} with AIR #${r.rank}!\n\n🏆 Percentile: ${r.percentile}%ile\n📊 ProveRank Platform — prove-rank.vercel.app`
          if(navigator.share) navigator.share({title:'My ProveRank Result',text}).catch(()=>{})
          else { navigator.clipboard?.writeText(text); toast('Result copied to clipboard!','s') }
        }

        return (
          <div style={{animation:'fadeIn .4s ease'}}>
            {/* Header */}
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:20,flexWrap:'wrap',gap:10}}>
              <div>
                <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>{t.title}</h1>
                <div style={{fontSize:13,color:C.sub}}>{t.sub}</div>
              </div>
              {results.length>0&&<button onClick={exportCSV} className="btn-g">📥 {t.export}</button>}
            </div>

            {/* SVG + Quote */}
            <div style={{background:'linear-gradient(135deg,rgba(255,215,0,0.08),rgba(0,22,40,0.85))',border:`1px solid rgba(255,215,0,0.2)`,borderRadius:20,padding:'20px 20px',marginBottom:24,display:'flex',alignItems:'center',gap:20,flexWrap:'wrap',position:'relative',overflow:'hidden'}}>
              <div style={{position:'absolute',right:16,top:'50%',transform:'translateY(-50%)',opacity:.1}}>
                <svg width="130" height="110" viewBox="0 0 130 110" fill="none">
                  <path d="M65 10 L78 45 L115 45 L85 67 L97 100 L65 80 L33 100 L45 67 L15 45 L52 45 Z" stroke="#FFD700" strokeWidth="2" fill="none"/>
                  <path d="M65 25 L74 50 L100 50 L79 63 L87 88 L65 73 L43 88 L51 63 L30 50 L56 50 Z" fill="rgba(255,215,0,0.2)"/>
                  <circle cx="20" cy="20" r="4" fill="#4D9FFF" opacity=".6"/>
                  <circle cx="110" cy="15" r="3" fill="#FF4D4D" opacity=".5"/>
                  <circle cx="115" cy="90" r="5" fill="#00C48C" opacity=".4"/>
                </svg>
              </div>
              <div style={{flex:1}}>
                <div style={{fontSize:15,color:C.gold,fontStyle:'italic',fontWeight:700,marginBottom:4}}>{t.quote}</div>
                <div style={{fontSize:12,color:C.sub}}>{t.quoteHi}</div>
              </div>
            </div>

            {/* Stats */}
            <div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:24}}>
              {[[t.testsTaken,results.length,'📝',C.primary],[t.bestScore,bestScore?`${bestScore}/720`:'—','🏆',C.gold],[t.avgScore,avgScore?`${avgScore}/720`:'—','📊',C.success],[t.bestRank,bestRank&&bestRank<99999?`#${bestRank}`:'—','🥇','#A78BFA']].map(([l,v,i,c])=>(
                <div key={String(l)} className="card-h" style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:14,padding:'16px 20px',flex:1,minWidth:120,backdropFilter:'blur(12px)',textAlign:'center',transition:'all .2s'}}>
                  <div style={{fontSize:22,marginBottom:6}}>{i}</div>
                  <div style={{fontSize:22,fontWeight:800,color:String(c),fontFamily:'Playfair Display,serif'}}>{v}</div>
                  <div style={{fontSize:11,color:C.sub,marginTop:3,fontWeight:600}}>{l}</div>
                </div>
              ))}
            </div>

            {/* Score Trend */}
            {results.length>1&&(
              <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:20,marginBottom:20,backdropFilter:'blur(12px)'}}>
                <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:'#0F172A',marginBottom:16}}>📈 {lang==='en'?'Score Trend':'स्कोर ट्रेंड'} ({lang==='en'?'Last 5 Tests':'पिछले 5 टेस्ट'})</div>
                <div style={{display:'flex',alignItems:'flex-end',gap:8,height:80}}>
                  {results.slice(0,5).reverse().map((r:any,i:number)=>{
                    const h = Math.round(((r.score||0)/720)*100)
                    return (
                      <div key={i} style={{flex:1,display:'flex',flexDirection:'column',alignItems:'center',gap:4}}>
                        <div style={{fontSize:10,color:C.primary,fontWeight:700}}>{r.score}</div>
                        <div style={{width:'100%',height:`${h}%`,background:`linear-gradient(180deg,${C.primary},rgba(77,159,255,0.3))`,borderRadius:'4px 4px 0 0',minHeight:4,transition:'height .6s ease'}}/>
                        <div style={{fontSize:9,color:C.sub,textAlign:'center',maxWidth:60,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{r.examTitle?.split(' ').slice(-1)[0]||`T${i+1}`}</div>
                      </div>
                    )
                  })}
                </div>
              </div>
            )}

            {/* Results Table */}
            <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,overflow:'hidden',backdropFilter:'blur(12px)',marginBottom:20}}>
              <div style={{padding:'16px 20px',borderBottom:`1px solid ${C.border}`,display:'flex',justifyContent:'space-between',alignItems:'center'}}>
                <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:'#0F172A'}}>📋 {t.allResults}</div>
              </div>
              {loading?(
                <div style={{textAlign:'center',padding:'40px',color:C.sub}}>⟳ Loading...</div>
              ):results.length===0?(
                <div style={{textAlign:'center',padding:'60px 20px',color:C.sub}}>
                  <svg width="70" height="70" viewBox="0 0 70 70" style={{display:'block',margin:'0 auto 14px'}} fill="none">
                    <circle cx="35" cy="35" r="30" stroke="#4D9FFF" strokeWidth="1.5" strokeDasharray="4 3"/>
                    <path d="M35 20 L38 29 L48 29 L40 34 L43 44 L35 38 L27 44 L30 34 L22 29 L32 29 Z" stroke="#FFD700" strokeWidth="1.5" fill="none"/>
                  </svg>
                  <div style={{fontWeight:700,fontSize:15,marginBottom:6}}>{t.noResults}</div>
                  <div style={{fontSize:12,marginBottom:16}}>{t.noResultsSub}</div>
                  <a href="/my-exams" className="btn-p" style={{textDecoration:'none',display:'inline-block'}}>{t.startNow}</a>
                </div>
              ):(
                results.map((r:any)=>(
                  <div key={r._id} style={{padding:'16px 20px',borderBottom:`1px solid ${C.border}`,transition:'background .15s'}}>
                    <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',flexWrap:'wrap',gap:10}}>
                      <div style={{flex:1,minWidth:200}}>
                        <div style={{fontWeight:700,fontSize:14,color:dm?C.text:'#0F172A',marginBottom:4}}>{r.examTitle||r.exam?.title||'—'}</div>
                        <div style={{fontSize:11,color:C.sub}}>{r.submittedAt?new Date(r.submittedAt).toLocaleDateString('en-IN',{day:'numeric',month:'short',year:'numeric'}):''}</div>
                        {/* Subject Scores */}
                        {r.subjectScores&&(
                          <div style={{display:'flex',gap:10,marginTop:6,flexWrap:'wrap'}}>
                            {[['⚛️',r.subjectScores.physics,180,'#00B4FF'],['🧪',r.subjectScores.chemistry,180,'#FF6B9D'],['🧬',r.subjectScores.biology,360,'#00E5A0']].map(([ic,sc,tot,col])=>(
                              sc!==undefined&&<span key={String(ic)} style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:`${col}15`,color:String(col),border:`1px solid ${col}30`}}>{ic} {sc}/{tot}</span>
                            ))}
                          </div>
                        )}
                      </div>
                      <div style={{display:'flex',gap:16,alignItems:'center',flexWrap:'wrap'}}>
                        <div style={{textAlign:'center'}}>
                          <div style={{fontWeight:800,fontSize:22,color:C.primary,fontFamily:'Playfair Display,serif'}}>{r.score}</div>
                          <div style={{fontSize:9,color:C.sub}}>/{r.totalMarks||720}</div>
                        </div>
                        <div style={{textAlign:'center'}}>
                          <div style={{fontWeight:700,fontSize:16,color:C.gold}}>#{r.rank||'—'}</div>
                          <div style={{fontSize:9,color:C.sub}}>AIR</div>
                        </div>
                        <div style={{textAlign:'center'}}>
                          <div style={{fontWeight:700,fontSize:16,color:C.success}}>{r.percentile||'—'}%</div>
                          <div style={{fontSize:9,color:C.sub}}>ile</div>
                        </div>
                        <div style={{display:'flex',gap:6,flexWrap:'wrap'}}>
                          <button onClick={()=>setSelResult(selResult?._id===r._id?null:r)} className="btn-g" style={{fontSize:11,padding:'6px 12px'}}>{t.viewDetails}</button>
                          <button onClick={()=>shareResult(r)} style={{padding:'6px 12px',background:'rgba(0,196,140,0.12)',color:C.success,border:'1px solid rgba(0,196,140,0.3)',borderRadius:8,cursor:'pointer',fontSize:11,fontFamily:'Inter,sans-serif',fontWeight:600}}>📤 {t.share}</button>
                        </div>
                      </div>
                    </div>

                    {/* Expanded Detail */}
                    {selResult?._id===r._id&&(
                      <div style={{marginTop:16,padding:16,background:'rgba(77,159,255,0.06)',borderRadius:12,border:`1px solid ${C.border}`}}>
                        <div style={{fontWeight:700,fontSize:13,marginBottom:12,color:dm?C.text:'#0F172A'}}>📊 {t.analysis}</div>
                        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(140px,1fr))',gap:10}}>
                          {[['✅ Correct',r.correct||'—',C.success],['❌ Wrong',r.wrong||'—',C.danger],['⭕ Skipped',r.unattempted||'—',C.sub],['📊 Accuracy',r.accuracy?`${r.accuracy}%`:'—',C.primary]].map(([l,v,c])=>(
                            <div key={String(l)} style={{background:'rgba(0,22,40,0.5)',borderRadius:10,padding:'10px',textAlign:'center',border:`1px solid ${C.border}`}}>
                              <div style={{fontWeight:700,fontSize:16,color:String(c)}}>{v}</div>
                              <div style={{fontSize:10,color:C.sub,marginTop:2}}>{l}</div>
                            </div>
                          ))}
                        </div>
                        <div style={{display:'flex',gap:8,marginTop:12,flexWrap:'wrap'}}>
                          <a href={`/results`} className="btn-g" style={{fontSize:11,textDecoration:'none'}}>📋 {t.omrView}</a>
                          <button className="btn-g" style={{fontSize:11}} onClick={()=>{
                            fetch(`${API}/api/results/${r._id}/receipt`,{headers:{Authorization:`Bearer ${token}`}}).then(res=>{if(res.ok)return res.blob()}).then(b=>{if(b){const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download='result_receipt.pdf';a.click()}}).catch(()=>toast('Receipt not available','w'))
                          }}>📄 {t.receipt}</button>
                        </div>
                      </div>
                    )}
                  </div>
                ))
              )}
            </div>
          </div>
        )
      }}
    </StudentShell>
  )
}
