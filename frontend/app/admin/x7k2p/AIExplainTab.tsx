'use client';
import { useState, useEffect } from 'react';

interface QItem { _id:string; text:string; subject:string; chapter?:string; difficulty:string; type:string; options?:string[]; correct?:number[]; explanation?:string; hindiExplanation?:string; }
interface ExpResult { questionId:string; explanation:string; qualityScore:number; steps:string[]; questionText:string; approved?:boolean; rejected?:boolean; }

const SUBJ_COLOR: Record<string,string> = { Physics:'#6366F1', Chemistry:'#10B981', Biology:'#F59E0B', Mathematics:'#EF4444' };

function Stars({ score }: { score:number }) {
  const colors = ['','#EF4444','#F97316','#F59E0B','#22C55E','#6366F1'];
  return (
    <span style={{ fontSize:13 }}>
      {[1,2,3,4,5].map(i => (
        <span key={i} style={{ color: i<=score ? colors[score] : 'rgba(255,255,255,0.15)' }}>★</span>
      ))}
      <span style={{ fontSize:10, color:'#64748B', marginLeft:4 }}>{score}/5</span>
    </span>
  );
}

export default function AIExplainTab({ API, token }: { API:string; token:string }) {
  const getToken = () => typeof window !== 'undefined' ? localStorage.getItem('pr_token')||'' : token;
  const S = {
    card:  { background:'rgba(255,255,255,0.04)', border:'1px solid rgba(255,255,255,0.09)', borderRadius:14, padding:'14px 16px', marginBottom:12 } as React.CSSProperties,
    cardY: { background:'rgba(252,211,77,0.06)', border:'1px solid rgba(252,211,77,0.25)', borderRadius:14, padding:'14px 16px', marginBottom:12 } as React.CSSProperties,
    bp:    { background:'linear-gradient(135deg,#6366F1,#8B5CF6)', color:'#fff', border:'none', borderRadius:9, padding:'9px 18px', fontWeight:700, fontSize:12, cursor:'pointer' } as React.CSSProperties,
    bg:    { background:'rgba(255,255,255,0.06)', color:'#E2E8F0', border:'1px solid rgba(255,255,255,0.12)', borderRadius:9, padding:'8px 14px', fontSize:12, cursor:'pointer' } as React.CSSProperties,
    bs:    { background:'linear-gradient(135deg,#10B981,#059669)', color:'#fff', border:'none', borderRadius:9, padding:'9px 16px', fontWeight:700, fontSize:12, cursor:'pointer' } as React.CSSProperties,
    br:    { background:'rgba(239,68,68,0.1)', color:'#FCA5A5', border:'1px solid rgba(239,68,68,0.3)', borderRadius:9, padding:'9px 14px', fontSize:12, cursor:'pointer' } as React.CSSProperties,
    inp:   { width:'100%', padding:'8px 12px', background:'rgba(255,255,255,0.05)', border:'1px solid rgba(255,255,255,0.1)', borderRadius:8, color:'#E2E8F0', fontSize:12, outline:'none', boxSizing:'border-box' as const },
    lbl:   { fontSize:10, fontWeight:700, color:'#94A3B8', textTransform:'uppercase' as const, letterSpacing:'0.5px', display:'block', marginBottom:5 },
  };

  const [queue,        setQueue]        = useState<QItem[]>([]);
  const [queueStats,   setQueueStats]   = useState({ totalNoExp:0, totalAll:0, withExp:0 });
  const [qSubjFilter,  setQSubjFilter]  = useState('all');
  const [loading,      setLoading]      = useState(false);
  const [activeQ,      setActiveQ]      = useState<QItem|null>(null);
  const [expResult,    setExpResult]    = useState<ExpResult|null>(null);
  const [genLoading,   setGenLoading]   = useState(false);
  const [explMode,     setExplMode]     = useState<'paragraph'|'steps'>('paragraph');
  const [explLang,     setExplLang]     = useState<'english'|'hindi'>('english');
  const [editText,     setEditText]     = useState('');
  const [flipped,      setFlipped]      = useState(false);
  const [saveMsg,      setSaveMsg]      = useState('');
  const [bulkSelected, setBulkSelected] = useState<string[]>([]);
  const [bulkRunning,  setBulkRunning]  = useState(false);
  const [bulkResults,  setBulkResults]  = useState<ExpResult[]>([]);
  const [bulkDone,     setBulkDone]     = useState(0);
  const [bulkTotal,    setBulkTotal]    = useState(0);
  const [bulkAutoSave, setBulkAutoSave] = useState(false);
  const [bulkMode,     setBulkMode]     = useState<'paragraph'|'steps'>('paragraph');
  const [bulkLang,     setBulkLang]     = useState<'english'|'hindi'>('english');

  useEffect(() => { loadQueue(); }, [qSubjFilter]);

  const loadQueue = async () => {
    setLoading(true);
    try {
      const res = await fetch(`${API}/api/questions/ai/explanation/queue?subject=${qSubjFilter}&limit=80`, { headers:{ Authorization:`Bearer ${getToken()}` } });
      const d = await res.json();
      if (d.success) { setQueue(d.questions); setQueueStats({ totalNoExp:d.totalNoExp, totalAll:d.totalAll, withExp:d.withExp }); }
    } catch(e){}
    setLoading(false);
  };

  // 18.1 Single generate
  const generateSingle = async (q:QItem) => {
    setActiveQ(q); setExpResult(null); setEditText(''); setFlipped(false); setGenLoading(true); setSaveMsg('');
    try {
      const res = await fetch(`${API}/api/questions/ai/explanation`, {
        method:'POST', headers:{ 'Content-Type':'application/json', Authorization:`Bearer ${getToken()}` },
        body: JSON.stringify({ questionId:q._id, mode:explMode, lang:explLang })
      });
      const d = await res.json();
      if (d.success) {
        setExpResult({ questionId:q._id, explanation:d.explanation, qualityScore:d.qualityScore, steps:d.steps||[], questionText:q.text });
        setEditText(d.explanation);
        setTimeout(() => setFlipped(true), 200);
      }
    } catch(e:any) { setSaveMsg('Error: '+e.message); }
    setGenLoading(false);
  };

  // 18.6 Hindi
  const generateHindi = async () => {
    if (!activeQ) return;
    setGenLoading(true);
    try {
      const res = await fetch(`${API}/api/questions/ai/explanation/hindi`, {
        method:'POST', headers:{ 'Content-Type':'application/json', Authorization:`Bearer ${getToken()}` },
        body: JSON.stringify({ questionId:activeQ._id, mode:explMode })
      });
      const d = await res.json();
      if (d.success) { setEditText(prev => prev + '\n\n[Hindi] ' + d.hindiExplanation); }
    } catch(e){}
    setGenLoading(false);
  };

  // 18.5 Approve
  const approveExplanation = async () => {
    if (!activeQ) return;
    setSaveMsg('Saving...');
    try {
      const res = await fetch(`${API}/api/questions/${activeQ._id}/explanation/save`, {
        method:'PUT', headers:{ 'Content-Type':'application/json', Authorization:`Bearer ${getToken()}` },
        body: JSON.stringify({ explanation:editText, action:'approve' })
      });
      const d = await res.json();
      if (d.success) {
        setSaveMsg('Approved!');
        setExpResult(prev => prev ? {...prev, approved:true} : null);
        setQueue(prev => prev.filter(q => q._id !== activeQ._id));
        setQueueStats(prev => ({...prev, totalNoExp:prev.totalNoExp-1, withExp:prev.withExp+1}));
        setTimeout(() => { setActiveQ(null); setExpResult(null); setSaveMsg(''); }, 1200);
      }
    } catch(e:any) { setSaveMsg('Error: '+e.message); }
  };

  // 18.5 Reject (18.17 red animation)
  const rejectExplanation = () => {
    setExpResult(prev => prev ? {...prev, rejected:true} : null);
    setFlipped(false);
    setTimeout(() => { setActiveQ(null); setExpResult(null); setSaveMsg(''); }, 600);
  };

  // 18.2 Bulk generate
  const runBulk = async () => {
    if (!bulkSelected.length) return;
    setBulkRunning(true); setBulkResults([]); setBulkDone(0); setBulkTotal(bulkSelected.length);
    const batchSize = 5;
    for (let i=0; i<bulkSelected.length; i+=batchSize) {
      const batch = bulkSelected.slice(i,i+batchSize);
      try {
        const res = await fetch(`${API}/api/questions/ai/explanation/bulk`, {
          method:'POST', headers:{ 'Content-Type':'application/json', Authorization:`Bearer ${getToken()}` },
          body: JSON.stringify({ questionIds:batch, mode:bulkMode, lang:bulkLang, autoSave:bulkAutoSave })
        });
        const d = await res.json();
        if (d.results) { setBulkResults(prev=>[...prev,...d.results.filter((r:any)=>r.success)]); setBulkDone(prev=>prev+d.done); if (bulkAutoSave) setQueue(prev=>prev.filter(q=>!batch.includes(q._id))); }
      } catch(e){}
    }
    setBulkRunning(false); loadQueue();
  };

  const pct = queueStats.totalAll > 0 ? Math.round((queueStats.withExp/queueStats.totalAll)*100) : 0;

  return (
    <div style={{ color:'#E2E8F0', fontFamily:'Inter,system-ui,sans-serif' }}>
      {/* Header */}
      <div style={{ marginBottom:20 }}>
        <div style={{ fontSize:22, fontWeight:800, background:'linear-gradient(135deg,#F59E0B,#FCD34D)', WebkitBackgroundClip:'text', WebkitTextFillColor:'transparent', marginBottom:4 }}>💡 AI Explanation Generator</div>
        <div style={{ fontSize:12, color:'#64748B' }}>AI-10 · Auto-generate, review & approve explanations — Feature 18</div>
      </div>

      {/* 18.12 Stats */}
      <div style={{ display:'grid', gridTemplateColumns:'repeat(4,1fr)', gap:10, marginBottom:14 }}>
        {[{l:'Total',val:queueStats.totalAll,c:'#6366F1'},{l:'With Expl.',val:queueStats.withExp,c:'#10B981'},{l:'Pending',val:queueStats.totalNoExp,c:'#F59E0B'},{l:'Coverage',val:pct+'%',c:pct>=80?'#10B981':pct>=50?'#F59E0B':'#EF4444'}].map(s=>(
          <div key={s.l} style={{...S.card,textAlign:'center',padding:'12px 8px'}}>
            <div style={{fontSize:22,fontWeight:800,color:s.c}}>{s.val}</div>
            <div style={{fontSize:10,color:'#64748B',marginTop:2}}>{s.l}</div>
          </div>
        ))}
      </div>

      {/* Coverage progress */}
      <div style={{marginBottom:16}}>
        <div style={{display:'flex',justifyContent:'space-between',fontSize:10,color:'#64748B',marginBottom:4}}><span>Explanation Coverage</span><span>{pct}%</span></div>
        <div style={{height:6,borderRadius:3,background:'rgba(255,255,255,0.08)'}}>
          <div style={{height:'100%',width:`${pct}%`,background:'linear-gradient(90deg,#F59E0B,#10B981)',borderRadius:3,transition:'width 0.5s'}}/>
        </div>
      </div>

      {/* Filters + Bulk controls */}
      <div style={{display:'flex',gap:8,marginBottom:12,flexWrap:'wrap',alignItems:'center'}}>
        <select value={qSubjFilter} onChange={e=>setQSubjFilter(e.target.value)} style={{...S.inp,width:'auto',padding:'5px 10px'}}>
          {['all','Physics','Chemistry','Biology','Mathematics'].map(s=><option key={s} value={s}>{s==='all'?'All Subjects':s}</option>)}
        </select>
        <button onClick={()=>setBulkSelected(queue.map(q=>q._id))} style={{...S.bg,padding:'5px 12px',fontSize:11}}>☑ Select All</button>
        <button onClick={()=>setBulkSelected([])} style={{...S.bg,padding:'5px 12px',fontSize:11}}>✕ Clear</button>
        <button onClick={loadQueue} style={{...S.bg,padding:'5px 12px',fontSize:11}}>🔄 Refresh</button>
        {/* Mode/Lang selectors */}
        <select value={explMode} onChange={e=>setExplMode(e.target.value as any)} style={{...S.inp,width:'auto',padding:'5px 10px',fontSize:11}}>
          <option value="paragraph">Paragraph</option>
          <option value="steps">Step-by-step (18.11)</option>
        </select>
        <select value={explLang} onChange={e=>setExplLang(e.target.value as any)} style={{...S.inp,width:'auto',padding:'5px 10px',fontSize:11}}>
          <option value="english">English</option>
          <option value="hindi">Hindi (18.6)</option>
        </select>
      </div>

      {/* 18.2 Bulk bar */}
      {bulkSelected.length>0&&(
        <div style={{...S.cardY,display:'flex',gap:10,alignItems:'center',flexWrap:'wrap',marginBottom:12}}>
          <span style={{fontSize:12,fontWeight:700,color:'#FCD34D'}}>⚡ {bulkSelected.length} selected</span>
          <select value={bulkMode} onChange={e=>setBulkMode(e.target.value as any)} style={{...S.inp,width:'auto',padding:'5px 8px',fontSize:11}}>
            <option value="paragraph">Paragraph</option><option value="steps">Steps</option>
          </select>
          <select value={bulkLang} onChange={e=>setBulkLang(e.target.value as any)} style={{...S.inp,width:'auto',padding:'5px 8px',fontSize:11}}>
            <option value="english">English</option><option value="hindi">Hindi</option>
          </select>
          <label style={{display:'flex',alignItems:'center',gap:5,fontSize:11,cursor:'pointer'}}>
            <input type="checkbox" checked={bulkAutoSave} onChange={e=>setBulkAutoSave(e.target.checked)}/>Auto-save (18.9)
          </label>
          <button onClick={runBulk} disabled={bulkRunning} style={{...S.bp,opacity:bulkRunning?0.7:1}}>
            {bulkRunning?`⟳ ${bulkDone}/${bulkTotal}...`:'🚀 Bulk Generate (18.2)'}
          </button>
        </div>
      )}

      {/* 18.16 Bulk progress bar */}
      {bulkRunning&&(
        <div style={{...S.card,borderColor:'rgba(99,102,241,0.3)',marginBottom:12}}>
          <div style={{display:'flex',justifyContent:'space-between',fontSize:12,marginBottom:6}}>
            <span style={{color:'#A5B4FC',fontWeight:700}}>⚡ Bulk Generation...</span>
            <span style={{color:'#6366F1',fontWeight:800}}>{bulkDone}/{bulkTotal}</span>
          </div>
          <div style={{height:8,borderRadius:4,background:'rgba(255,255,255,0.08)'}}>
            <div style={{height:'100%',width:`${bulkTotal>0?Math.round((bulkDone/bulkTotal)*100):0}%`,background:'linear-gradient(90deg,#6366F1,#A78BFA)',borderRadius:4,transition:'width 0.3s'}}/>
          </div>
          <div style={{fontSize:10,color:'#64748B',marginTop:4}}>{bulkDone}/{bulkTotal} explanations generated</div>
        </div>
      )}

      {/* Bulk results */}
      {bulkResults.length>0&&!bulkRunning&&(
        <div style={{marginBottom:16}}>
          <div style={{fontSize:12,fontWeight:700,color:'#10B981',marginBottom:8}}>✅ {bulkResults.length} explanations ready!</div>
          {bulkResults.slice(0,5).map((r,i)=>(
            <div key={i} style={{...S.card,borderColor:'rgba(16,185,129,0.2)'}}>
              <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:5}}>
                <span style={{fontSize:10,color:'#94A3B8'}}>Q{i+1}: {r.questionText?.slice(0,60)}...</span>
                <Stars score={r.qualityScore}/>
              </div>
              {/* 18.15 Yellow highlight */}
              <div style={{fontSize:11,color:'#FCD34D',background:'rgba(252,211,77,0.06)',border:'1px solid rgba(252,211,77,0.15)',borderRadius:8,padding:'7px 10px',lineHeight:1.7}}>
                💡 {r.explanation?.slice(0,200)}{r.explanation?.length>200?'...':''}
              </div>
            </div>
          ))}
          {bulkResults.length>5&&<div style={{fontSize:11,color:'#64748B',textAlign:'center',padding:8}}>+{bulkResults.length-5} more...</div>}
        </div>
      )}

      {/* 18.12 Queue list header */}
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:10}}>
        <div style={{fontSize:12,fontWeight:700,color:'#F59E0B'}}>
          📋 Pending Queue ({queue.length}) — Questions without explanation
        </div>
      </div>

      {loading&&<div style={{textAlign:'center',padding:20,color:'#64748B'}}>⟳ Loading queue...</div>}

      {/* Question cards */}
      {queue.map(q=>(
        <div key={q._id} style={{...S.card, borderColor:bulkSelected.includes(q._id)?'rgba(99,102,241,0.5)':'rgba(255,255,255,0.09)', background:bulkSelected.includes(q._id)?'rgba(99,102,241,0.08)':'rgba(255,255,255,0.04)', transition:'all 0.2s'}}>
          {/* 18.14 Before/After split view */}
          <div style={{display:'grid',gridTemplateColumns:'1fr auto',gap:12,alignItems:'flex-start'}}>
            <div>
              <div style={{display:'flex',gap:5,marginBottom:6,flexWrap:'wrap',alignItems:'center'}}>
                <input type="checkbox" checked={bulkSelected.includes(q._id)} onChange={()=>setBulkSelected(prev=>prev.includes(q._id)?prev.filter(x=>x!==q._id):[...prev,q._id])}/>
                <span style={{fontSize:10,padding:'2px 8px',borderRadius:10,background:`${SUBJ_COLOR[q.subject]||'#6366F1'}18`,color:SUBJ_COLOR[q.subject]||'#A5B4FC',border:`1px solid ${SUBJ_COLOR[q.subject]||'#6366F1'}30`,fontWeight:700}}>{q.subject}</span>
                <span style={{fontSize:10,padding:'2px 7px',borderRadius:10,background:'rgba(255,255,255,0.05)',color:'#64748B'}}>{q.difficulty}</span>
                {q.chapter&&<span style={{fontSize:10,color:'#64748B'}}>📖 {q.chapter}</span>}
                {/* 18.7 Already has explanation — Regenerate label */}
                {q.explanation&&<span style={{fontSize:10,padding:'2px 7px',borderRadius:10,background:'rgba(245,158,11,0.1)',color:'#FCD34D'}}>🔄 Has exp</span>}
              </div>
              <div style={{fontSize:12,color:'#E2E8F0',lineHeight:1.6}}>{q.text?.slice(0,180)}{q.text?.length>180?'...':''}</div>
            </div>
            <div style={{display:'flex',flexDirection:'column',gap:5,minWidth:120}}>
              {/* 18.1 Generate / 18.7 Regenerate */}
              <button onClick={()=>generateSingle(q)} style={{...S.bp,fontSize:10,padding:'6px 12px',whiteSpace:'nowrap'}}>
                {q.explanation?'🔄 Regen':'💡 Generate'}
              </button>
              <button onClick={()=>{setBulkSelected(prev=>prev.includes(q._id)?prev.filter(x=>x!==q._id):[...prev,q._id])}} style={{...S.bg,fontSize:10,padding:'5px 8px',textAlign:'center'}}>
                {bulkSelected.includes(q._id)?'☑ Selected':'☐ Select'}
              </button>
            </div>
          </div>
        </div>
      ))}

      {queue.length===0&&!loading&&(
        <div style={{textAlign:'center',padding:40,color:'#64748B'}}>
          <div style={{fontSize:32,marginBottom:8}}>🎉</div>
          <div style={{fontSize:14,fontWeight:700,color:'#10B981'}}>All questions have explanations!</div>
        </div>
      )}

      {/* 18.13 Card flip modal */}
      {activeQ&&(
        <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.85)',backdropFilter:'blur(8px)',zIndex:9999,display:'flex',alignItems:'center',justifyContent:'center',padding:16}}
          onClick={e=>e.target===e.currentTarget&&!genLoading&&setActiveQ(null)}>
          <div style={{width:'100%',maxWidth:640,maxHeight:'92vh',overflowY:'auto'}}>
            <div style={{perspective:1000}}>
              <div style={{transition:'transform 0.6s',transformStyle:'preserve-3d',transform:flipped?'rotateY(180deg)':'rotateY(0deg)',position:'relative',minHeight:250}}>

                {/* FRONT — Question */}
                <div style={{position:flipped?'absolute':'relative',inset:0,backfaceVisibility:'hidden',background:'#0F1120',border:'1px solid rgba(99,102,241,0.4)',borderRadius:16,padding:20}}>
                  <div style={{display:'flex',justifyContent:'space-between',marginBottom:12}}>
                    <span style={{fontSize:14,fontWeight:700,color:'#A5B4FC'}}>📄 Question (18.14 — Before)</span>
                    <button onClick={()=>setActiveQ(null)} style={{background:'none',border:'none',color:'#64748B',fontSize:18,cursor:'pointer'}}>✕</button>
                  </div>
                  <div style={{fontSize:13,color:'#E2E8F0',lineHeight:1.7,marginBottom:12}}>{activeQ.text}</div>
                  {(activeQ.options||[]).map((opt,i)=>{
                    const isCor=(activeQ.correct||[]).includes(i);
                    return(<div key={i} style={{padding:'6px 10px',borderRadius:7,marginBottom:4,background:isCor?'rgba(16,185,129,0.12)':'rgba(255,255,255,0.03)',border:`1px solid ${isCor?'rgba(16,185,129,0.4)':'rgba(255,255,255,0.07)'}`,fontSize:12,color:isCor?'#6EE7B7':'#94A3B8'}}>
                      <b>{String.fromCharCode(65+i)})</b> {opt} {isCor&&'✅'}
                    </div>);
                  })}
                  {/* 18.8 Progress indicator */}
                  {genLoading&&(
                    <div style={{marginTop:14,padding:'10px 14px',background:'rgba(99,102,241,0.08)',borderRadius:10,display:'flex',alignItems:'center',gap:8}}>
                      <div style={{width:14,height:14,border:'2px solid #6366F1',borderTopColor:'transparent',borderRadius:'50%',animation:'spin 0.8s linear infinite'}}/>
                      <span style={{fontSize:12,color:'#A5B4FC'}}>AI generating explanation... (18.8)</span>
                    </div>
                  )}
                </div>

                {/* BACK — AI Explanation (18.13 / 18.14 After) */}
                <div style={{position:'absolute',inset:0,backfaceVisibility:'hidden',transform:'rotateY(180deg)',background:'#0F1120',border:'1px solid rgba(252,211,77,0.4)',borderRadius:16,padding:20}}>
                  <div style={{display:'flex',justifyContent:'space-between',marginBottom:10}}>
                    <span style={{fontSize:14,fontWeight:700,color:'#FCD34D'}}>💡 AI Explanation (18.14 — After)</span>
                    {expResult&&<Stars score={expResult.qualityScore}/>}
                  </div>

                  {/* 18.3 Preview */}
                  {expResult&&(
                    <div style={{marginBottom:8,padding:'8px 12px',background:'rgba(252,211,77,0.05)',border:'1px solid rgba(252,211,77,0.15)',borderRadius:8}}>
                      <div style={{fontSize:10,color:'#F59E0B',fontWeight:700,marginBottom:4}}>👁️ PREVIEW (18.3) · Quality: <Stars score={expResult.qualityScore}/></div>
                      <div style={{fontSize:11,color:'#FCD34D',lineHeight:1.7}}>{expResult.explanation?.slice(0,200)}</div>
                    </div>
                  )}

                  {/* 18.11 Steps */}
                  {expResult?.steps&&expResult.steps.length>0&&(
                    <div style={{marginBottom:8,padding:'8px 12px',background:'rgba(99,102,241,0.06)',border:'1px solid rgba(99,102,241,0.2)',borderRadius:8}}>
                      <div style={{fontSize:10,fontWeight:700,color:'#A5B4FC',marginBottom:5}}>📋 STEP-BY-STEP (18.11)</div>
                      {expResult.steps.map((step,i)=>(
                        <div key={i} style={{fontSize:11,color:'#C4B5FD',marginBottom:3,display:'flex',gap:5}}>
                          <span style={{color:'#6366F1',fontWeight:700,flexShrink:0}}>Step {i+1}:</span>{step}
                        </div>
                      ))}
                    </div>
                  )}

                  {/* 18.4 Edit textarea — 18.15 Yellow highlight */}
                  <div style={{marginBottom:10}}>
                    <label style={S.lbl}>Edit Explanation (18.4) — LaTeX supported</label>
                    <textarea value={editText} onChange={e=>setEditText(e.target.value)} rows={5}
                      style={{...S.inp,resize:'vertical',background:'rgba(252,211,77,0.06)',border:'1px solid rgba(252,211,77,0.3)',color:'#FCD34D',lineHeight:1.7}}/>
                  </div>

                  {/* 18.5 Actions */}
                  <div style={{display:'flex',gap:7,flexWrap:'wrap',marginBottom:8}}>
                    {/* 18.17 Approve = green glow */}
                    <button onClick={approveExplanation} style={{...S.bs,flex:1,
                      boxShadow:expResult?.approved?'0 0 18px rgba(16,185,129,0.6)':'none',
                      transition:'box-shadow 0.3s'}}>
                      ✅ Approve & Save (18.5)
                    </button>
                    {/* 18.17 Reject = red */}
                    <button onClick={rejectExplanation} style={{...S.br,flex:1,
                      textDecoration:expResult?.rejected?'line-through':'none',
                      transition:'all 0.3s'}}>
                      ❌ Reject (18.5)
                    </button>
                    <button onClick={()=>generateSingle(activeQ)} disabled={genLoading} style={{...S.bp,flex:1,opacity:genLoading?0.6:1}}>
                      🔄 Regenerate (18.5)
                    </button>
                  </div>
                  <div style={{display:'flex',gap:7}}>
                    {/* 18.6 Hindi */}
                    <button onClick={generateHindi} disabled={genLoading} style={{...S.bg,flex:1,fontSize:11}}>🇮🇳 Hindi Explanation (18.6)</button>
                    <button onClick={()=>setFlipped(false)} style={{...S.bg,flex:1,fontSize:11}}>← Back to Question</button>
                  </div>

                  {saveMsg&&(
                    <div style={{marginTop:8,padding:'7px 10px',borderRadius:8,
                      background:saveMsg.includes('Approved')||saveMsg.includes('Saving')?'rgba(16,185,129,0.1)':'rgba(239,68,68,0.1)',
                      color:saveMsg.includes('Approved')||saveMsg.includes('Saving')?'#6EE7B7':'#FCA5A5',fontSize:12}}>
                      {saveMsg}
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
      <style>{`@keyframes spin{to{transform:rotate(360deg);}}`}</style>
    </div>
  );
}
