'use client';
import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import { getToken, getRole } from '@/lib/auth';

// ── Mini Chart Components (no external lib needed) ──

// C1: Pie/Donut Chart
function DonutChart({ correct, wrong, unattempted, total }: { correct:number; wrong:number; unattempted:number; total:number }) {
  const size = 160; const r = 60; const cx = 80; const cy = 80; const stroke = 18;
  const circ = 2 * Math.PI * r;
  const cPct = correct / total;
  const wPct = wrong / total;
  const uPct = unattempted / total;
  const cDash = cPct * circ;
  const wDash = wPct * circ;
  const uDash = uPct * circ;
  const cOffset = 0;
  const wOffset = -cDash;
  const uOffset = -(cDash + wDash);
  return (
    <div style={{display:'flex',flexDirection:'column',alignItems:'center',gap:12}}>
      <svg width={size} height={size} style={{transform:'rotate(-90deg)'}}>
        <circle cx={cx} cy={cy} r={r} fill="none" stroke="#1E3A5F" strokeWidth={stroke}/>
        {correct>0 && <circle cx={cx} cy={cy} r={r} fill="none" stroke="#22C55E" strokeWidth={stroke} strokeDasharray={`${cDash} ${circ}`} strokeDashoffset={cOffset} strokeLinecap="butt"/>}
        {wrong>0 && <circle cx={cx} cy={cy} r={r} fill="none" stroke="#EF4444" strokeWidth={stroke} strokeDasharray={`${wDash} ${circ}`} strokeDashoffset={wOffset} strokeLinecap="butt"/>}
        {unattempted>0 && <circle cx={cx} cy={cy} r={r} fill="none" stroke="#6B7280" strokeWidth={stroke} strokeDasharray={`${uDash} ${circ}`} strokeDashoffset={uOffset} strokeLinecap="butt"/>}
      </svg>
      <div style={{display:'flex',gap:16,flexWrap:'wrap',justifyContent:'center'}}>
        {[{c:'#22C55E',l:`Correct: ${correct}`},{c:'#EF4444',l:`Wrong: ${wrong}`},{c:'#6B7280',l:`Skipped: ${unattempted}`}].map(({c,l})=>(
          <div key={l} style={{display:'flex',alignItems:'center',gap:5,fontSize:12,color:'#94A3B8'}}>
            <div style={{width:10,height:10,borderRadius:2,background:c}}/>
            {l}
          </div>
        ))}
      </div>
    </div>
  );
}

// C2: Bar Chart
function BarChart({ data }: { data: {label:string; correct:number; wrong:number; total:number}[] }) {
  const maxVal = Math.max(...data.map(d => d.total), 1);
  return (
    <div style={{display:'flex',gap:16,alignItems:'flex-end',justifyContent:'center',height:120,padding:'0 8px'}}>
      {data.map(d => (
        <div key={d.label} style={{display:'flex',flexDirection:'column',alignItems:'center',gap:4,flex:1}}>
          <div style={{fontSize:10,color:'#22C55E',fontWeight:600}}>{d.correct}</div>
          <div style={{width:'100%',display:'flex',flexDirection:'column',justifyContent:'flex-end',height:90,gap:2}}>
            <div style={{width:'100%',height:`${(d.correct/maxVal)*80}px`,background:'linear-gradient(180deg,#22C55E,#16A34A)',borderRadius:'4px 4px 0 0',minHeight:4,transition:'height 0.6s ease'}}/>
            <div style={{width:'100%',height:`${(d.wrong/maxVal)*80}px`,background:'linear-gradient(180deg,#EF4444,#DC2626)',borderRadius:'4px 4px 0 0',minHeight:d.wrong>0?4:0,transition:'height 0.6s ease'}}/>
          </div>
          <div style={{fontSize:11,color:'#6B8FAF',textAlign:'center'}}>{d.label}</div>
        </div>
      ))}
    </div>
  );
}

// A1: Answer Key Row
function AnswerRow({ q, idx }: { q: any; idx: number }) {
  const isCorrect = q.selectedAnswer === q.correctAnswer;
  const isSkipped = !q.selectedAnswer;
  const bgColor = isSkipped ? 'rgba(107,114,128,0.08)' : isCorrect ? 'rgba(34,197,94,0.08)' : 'rgba(239,68,68,0.08)';
  const borderColor = isSkipped ? '#374151' : isCorrect ? '#22C55E' : '#EF4444';
  const icon = isSkipped ? '—' : isCorrect ? '✓' : '✗';
  const iconColor = isSkipped ? '#6B7280' : isCorrect ? '#22C55E' : '#EF4444';
  return (
    <div style={{background:bgColor,border:`1px solid ${borderColor}`,borderRadius:10,padding:'12px 14px',marginBottom:8}}>
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',gap:8}}>
        <div style={{flex:1}}>
          <span style={{fontSize:11,color:'#6B8FAF',fontWeight:600}}>Q{idx+1} · {q.subject}</span>
          <p style={{fontSize:13,color:'#E8F4FF',margin:'4px 0 8px',lineHeight:1.5}}>{q.question}</p>
          <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
            {['A','B','C','D'].map(opt => {
              const isSelected = q.selectedAnswer === opt;
              const isCorrectOpt = q.correctAnswer === opt;
              let optBg = 'rgba(0,22,40,0.5)';
              let optBorder = '#002D55';
              let optColor = '#94A3B8';
              if (isCorrectOpt) { optBg='rgba(34,197,94,0.15)'; optBorder='#22C55E'; optColor='#22C55E'; }
              if (isSelected && !isCorrectOpt) { optBg='rgba(239,68,68,0.15)'; optBorder='#EF4444'; optColor='#EF4444'; }
              return (
                <div key={opt} style={{padding:'4px 12px',borderRadius:6,border:`1px solid ${optBorder}`,background:optBg,fontSize:12,color:optColor,fontWeight:isSelected||isCorrectOpt?600:400}}>
                  {opt}: {q[`option${opt}`]}
                </div>
              );
            })}
          </div>
        </div>
        <div style={{fontSize:20,color:iconColor,fontWeight:700,flexShrink:0}}>{icon}</div>
      </div>
      {q.explanation && (
        <div style={{marginTop:8,padding:'8px 10px',background:'rgba(77,159,255,0.06)',borderRadius:6,fontSize:12,color:'#6B8FAF',borderLeft:'2px solid #4D9FFF'}}>
          💡 {q.explanation}
        </div>
      )}
    </div>
  );
}

// ── Mock Data (real data API se aayega) ──
const MOCK_RESULT = {
  examTitle: 'NEET Mock Test — Series 1',
  studentName: 'Student Name',
  attemptDate: '2025-01-15',
  timeTaken: '2h 45m',
  score: 540,
  maxScore: 720,
  rank: 42,
  totalStudents: 1250,
  percentile: 96.6,
  correct: 135,
  wrong: 30,
  unattempted: 15,
  total: 180,
  subjects: [
    { label:'Physics', correct:42, wrong:10, unattempted:8, total:60, marks:160 },
    { label:'Chemistry', correct:48, wrong:8, unattempted:4, total:60, marks:188 },
    { label:'Biology', correct:45, wrong:12, unattempted:3, total:60, marks:168 },
  ],
  questions: [
    { subject:'Physics', question:'A particle moves with uniform velocity. Its acceleration is:', selectedAnswer:'A', correctAnswer:'A', optionA:'Zero', optionB:'Constant non-zero', optionC:'Variable', optionD:'Infinite', explanation:'Uniform velocity means no change in velocity, so acceleration = 0.' },
    { subject:'Chemistry', question:'The atomic number of Carbon is:', selectedAnswer:'B', correctAnswer:'B', optionA:'5', optionB:'6', optionC:'7', optionD:'8', explanation:'Carbon has 6 protons, so atomic number = 6.' },
    { subject:'Biology', question:'Which organelle is called the powerhouse of the cell?', selectedAnswer:'A', correctAnswer:'A', optionA:'Mitochondria', optionB:'Nucleus', optionC:'Ribosome', optionD:'Golgi body', explanation:'Mitochondria produces ATP through cellular respiration.' },
    { subject:'Physics', question:'SI unit of force is:', selectedAnswer:'C', correctAnswer:'B', optionA:'Joule', optionB:'Newton', optionC:'Pascal', optionD:'Watt', explanation:'Newton (N) = kg·m/s² is the SI unit of force.' },
    { subject:'Chemistry', question:'pH of pure water at 25°C is:', selectedAnswer:'', correctAnswer:'B', optionA:'0', optionB:'7', optionC:'14', optionD:'1', explanation:'Pure water is neutral with pH = 7.' },
  ],
};

export default function ResultPage() {
  const router = useRouter();
  const params = useParams();
  const attemptId = params?.attemptId as string;
  const [result, setResult] = useState<typeof MOCK_RESULT | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'overview'|'subjects'|'answers'|'trend'>('overview');
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    if (!getToken()) { router.push('/login'); return; }
    // API call — fallback to mock
    const fetchResult = async () => {
      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/results/${attemptId}`, {
          headers: { Authorization: `Bearer ${getToken()}` }
        });
        if (res.ok) { const data = await res.json(); setResult(data); }
        else setResult(MOCK_RESULT);
      } catch { setResult(MOCK_RESULT); }
      finally { setLoading(false); }
    };
    fetchResult();
  }, [attemptId, router]);

  if (!mounted || loading) return (
    <div style={{minHeight:'100vh',background:'#000A18',display:'flex',alignItems:'center',justifyContent:'center'}}>
      <div style={{textAlign:'center'}}>
        <div style={{fontSize:40,marginBottom:16,animation:'spin 1s linear infinite'}}>⟳</div>
        <div style={{color:'#4D9FFF',fontSize:16}}>Loading result...</div>
        <style>{`@keyframes spin{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}`}</style>
      </div>
    </div>
  );

  if (!result) return <div style={{minHeight:'100vh',background:'#000A18',display:'flex',alignItems:'center',justifyContent:'center',color:'#EF4444',fontSize:18}}>Result not found</div>;

  const scorePercent = Math.round((result.score / result.maxScore) * 100);
  const tabs = [{k:'overview',l:'📊 Overview'},{k:'subjects',l:'📚 Subjects'},{k:'answers',l:'📝 Answers'},{k:'trend',l:'📈 History'}];

  return (
    <div style={{minHeight:'100vh',background:'#000A18',fontFamily:'Inter,sans-serif',color:'#E8F4FF'}}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600&display=swap');
        @keyframes fadeUp{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:translateY(0)}}
        @keyframes scoreCount{from{opacity:0;transform:scale(0.8)}to{opacity:1;transform:scale(1)}}
        ::-webkit-scrollbar{width:4px} ::-webkit-scrollbar-track{background:#000A18} ::-webkit-scrollbar-thumb{background:#002D55;border-radius:2px}
      `}</style>

      {/* ── HEADER ── */}
      <div style={{background:'#001628',borderBottom:'1px solid #002D55',padding:'14px 20px',display:'flex',alignItems:'center',gap:12,position:'sticky',top:0,zIndex:50}}>
        <button onClick={()=>router.back()} style={{background:'rgba(77,159,255,0.1)',border:'1px solid #002D55',borderRadius:8,color:'#4D9FFF',padding:'6px 12px',cursor:'pointer',fontSize:13,fontFamily:'Inter,sans-serif'}}>
          ← Back
        </button>
        <div>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:'#E8F4FF'}}>{result.examTitle}</div>
          <div style={{fontSize:11,color:'#6B8FAF'}}>{result.attemptDate} · Time taken: {result.timeTaken}</div>
        </div>
        <button onClick={()=>router.push('/dashboard/results/history')} style={{marginLeft:'auto',background:'transparent',border:'1px solid #002D55',borderRadius:8,color:'#6B8FAF',padding:'6px 12px',cursor:'pointer',fontSize:12,fontFamily:'Inter,sans-serif'}}>
          All Results →
        </button>
      </div>

      {/* ── SCORE HERO CARD ── */}
      <div style={{padding:'20px 16px 0',animation:'fadeUp 0.5s ease'}}>
        <div style={{background:'linear-gradient(135deg,#001628 0%,#002D55 50%,#001628 100%)',border:'1px solid rgba(77,159,255,0.3)',borderRadius:20,padding:'28px 20px',textAlign:'center',position:'relative',overflow:'hidden'}}>
          {/* Glow */}
          <div style={{position:'absolute',top:-40,left:'50%',transform:'translateX(-50%)',width:200,height:200,background:'radial-gradient(circle,rgba(77,159,255,0.12) 0%,transparent 70%)',pointerEvents:'none'}}/>

          <div style={{fontSize:12,color:'#6B8FAF',letterSpacing:2,textTransform:'uppercase',marginBottom:12}}>Your Score</div>

          {/* Score Circle */}
          <div style={{position:'relative',display:'inline-block',marginBottom:16}}>
            <svg width={140} height={140} style={{transform:'rotate(-90deg)'}}>
              <circle cx={70} cy={70} r={58} fill="none" stroke="#1E3A5F" strokeWidth={10}/>
              <circle cx={70} cy={70} r={58} fill="none" stroke="#4D9FFF" strokeWidth={10}
                strokeDasharray={`${(scorePercent/100)*364} 364`} strokeLinecap="round"/>
            </svg>
            <div style={{position:'absolute',inset:0,display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center'}}>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:32,fontWeight:700,color:'#E8F4FF',animation:'scoreCount 0.8s ease',lineHeight:1}}>{result.score}</div>
              <div style={{fontSize:13,color:'#6B8FAF'}}>/ {result.maxScore}</div>
            </div>
          </div>

          {/* Stats Row */}
          <div style={{display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:12,marginTop:8}}>
            {[
              {l:'Rank',v:`#${result.rank}`,sub:`of ${result.totalStudents}`,c:'#F59E0B'},
              {l:'Percentile',v:`${result.percentile}%`,sub:'Top performers',c:'#4D9FFF'},
              {l:'Accuracy',v:`${Math.round((result.correct/result.total)*100)}%`,sub:`${result.correct}/${result.total} correct`,c:'#22C55E'},
            ].map(({l,v,sub,c})=>(
              <div key={l} style={{background:'rgba(0,22,40,0.6)',borderRadius:12,padding:'12px 8px',border:'1px solid #002D55'}}>
                <div style={{fontSize:11,color:'#6B8FAF',marginBottom:4}}>{l}</div>
                <div style={{fontSize:20,fontWeight:700,color:c,fontFamily:'Playfair Display,serif'}}>{v}</div>
                <div style={{fontSize:10,color:'#3A5A7A',marginTop:2}}>{sub}</div>
              </div>
            ))}
          </div>

          {/* Quick stats */}
          <div style={{display:'flex',justifyContent:'center',gap:20,marginTop:16}}>
            {[{l:'✅ Correct',v:result.correct,c:'#22C55E'},{l:'❌ Wrong',v:result.wrong,c:'#EF4444'},{l:'⬜ Skipped',v:result.unattempted,c:'#6B7280'}].map(({l,v,c})=>(
              <div key={l} style={{textAlign:'center'}}>
                <div style={{fontSize:18,fontWeight:700,color:c}}>{v}</div>
                <div style={{fontSize:11,color:'#6B8FAF'}}>{l}</div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* ── TABS ── */}
      <div style={{padding:'16px 16px 0',position:'sticky',top:57,zIndex:40,background:'#000A18'}}>
        <div style={{display:'flex',gap:4,background:'rgba(0,22,40,0.8)',borderRadius:12,padding:4,border:'1px solid #002D55',backdropFilter:'blur(10px)'}}>
          {tabs.map(tab=>(
            <button key={tab.k} onClick={()=>setActiveTab(tab.k as typeof activeTab)}
              style={{flex:1,padding:'9px 4px',borderRadius:8,border:'none',background:activeTab===tab.k?'#4D9FFF':'transparent',color:activeTab===tab.k?'white':'#6B8FAF',fontSize:11,fontWeight:600,cursor:'pointer',fontFamily:'Inter,sans-serif',transition:'all 0.2s'}}>
              {tab.l}
            </button>
          ))}
        </div>
      </div>

      {/* ── TAB CONTENT ── */}
      <div style={{padding:'16px'}}>

        {/* ── OVERVIEW TAB ── */}
        {activeTab==='overview' && (
          <div style={{animation:'fadeUp 0.4s ease'}}>
            <div style={{background:'#001628',border:'1px solid #002D55',borderRadius:16,padding:'20px 16px',marginBottom:16}}>
              <div style={{fontSize:14,fontWeight:600,color:'#E8F4FF',marginBottom:16,fontFamily:'Playfair Display,serif'}}>📊 Answer Distribution</div>
              <DonutChart correct={result.correct} wrong={result.wrong} unattempted={result.unattempted} total={result.total}/>
            </div>
            <div style={{background:'#001628',border:'1px solid #002D55',borderRadius:16,padding:'20px 16px'}}>
              <div style={{fontSize:14,fontWeight:600,color:'#E8F4FF',marginBottom:16,fontFamily:'Playfair Display,serif'}}>📈 Subject Performance</div>
              <BarChart data={result.subjects}/>
              <div style={{display:'flex',gap:12,justifyContent:'center',marginTop:8}}>
                <div style={{display:'flex',alignItems:'center',gap:4,fontSize:11,color:'#94A3B8'}}><div style={{width:10,height:10,borderRadius:2,background:'#22C55E'}}/> Correct</div>
                <div style={{display:'flex',alignItems:'center',gap:4,fontSize:11,color:'#94A3B8'}}><div style={{width:10,height:10,borderRadius:2,background:'#EF4444'}}/> Wrong</div>
              </div>
            </div>
          </div>
        )}

        {/* ── SUBJECTS TAB ── */}
        {activeTab==='subjects' && (
          <div style={{animation:'fadeUp 0.4s ease',display:'flex',flexDirection:'column',gap:12}}>
            {result.subjects.map(subj=>{
              const acc = Math.round((subj.correct/subj.total)*100);
              const accColor = acc>=70?'#22C55E':acc>=40?'#F59E0B':'#EF4444';
              return (
                <div key={subj.label} style={{background:'#001628',border:'1px solid #002D55',borderRadius:16,padding:'18px 16px'}}>
                  <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:14}}>
                    <div style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:'#E8F4FF'}}>{subj.label}</div>
                    <div style={{fontSize:22,fontWeight:700,color:'#4D9FFF',fontFamily:'Playfair Display,serif'}}>{subj.marks} <span style={{fontSize:12,color:'#6B8FAF'}}>marks</span></div>
                  </div>
                  {/* Progress bar */}
                  <div style={{height:6,background:'#1E3A5F',borderRadius:3,marginBottom:12,overflow:'hidden'}}>
                    <div style={{height:'100%',width:`${acc}%`,background:`linear-gradient(90deg,${accColor},${accColor}88)`,borderRadius:3,transition:'width 1s ease'}}/>
                  </div>
                  <div style={{display:'grid',gridTemplateColumns:'repeat(4,1fr)',gap:8}}>
                    {[{l:'Total',v:subj.total,c:'#6B8FAF'},{l:'Correct',v:subj.correct,c:'#22C55E'},{l:'Wrong',v:subj.wrong,c:'#EF4444'},{l:'Skipped',v:subj.unattempted,c:'#6B7280'}].map(({l,v,c})=>(
                      <div key={l} style={{textAlign:'center',background:'rgba(0,22,40,0.5)',borderRadius:8,padding:'8px 4px'}}>
                        <div style={{fontSize:16,fontWeight:700,color:c}}>{v}</div>
                        <div style={{fontSize:10,color:'#6B8FAF'}}>{l}</div>
                      </div>
                    ))}
                  </div>
                  <div style={{marginTop:10,fontSize:12,color:accColor,fontWeight:600,textAlign:'right'}}>
                    Accuracy: {acc}%
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {/* ── ANSWERS TAB ── */}
        {activeTab==='answers' && (
          <div style={{animation:'fadeUp 0.4s ease'}}>
            <div style={{fontSize:13,color:'#6B8FAF',marginBottom:12}}>
              📝 Answer Key — {result.questions.length} questions shown · <span style={{color:'#4D9FFF'}}>Full solutions included</span>
            </div>
            {result.questions.map((q,i) => <AnswerRow key={i} q={q} idx={i}/>)}
          </div>
        )}

        {/* ── HISTORY/TREND TAB ── */}
        {activeTab==='trend' && (
          <div style={{animation:'fadeUp 0.4s ease'}}>
            <div style={{background:'#001628',border:'1px solid #002D55',borderRadius:16,padding:'20px 16px',marginBottom:16}}>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:'#E8F4FF',marginBottom:4}}>📈 Performance Trend</div>
              <div style={{fontSize:12,color:'#6B8FAF',marginBottom:20}}>Your score over last 5 attempts</div>
              {/* P1: Simple line trend */}
              {[
                {exam:'Mock 1',score:380,max:720},{exam:'Mock 2',score:420,max:720},{exam:'Mock 3',score:480,max:720},
                {exam:'Mock 4',score:510,max:720},{exam:'Mock 5',score:result.score,max:result.maxScore},
              ].map((attempt,i,arr)=>{
                const pct = Math.round((attempt.score/attempt.max)*100);
                const isLatest = i===arr.length-1;
                return (
                  <div key={attempt.exam} style={{display:'flex',alignItems:'center',gap:12,marginBottom:10}}>
                    <div style={{fontSize:11,color:'#6B8FAF',width:52,flexShrink:0}}>{attempt.exam}</div>
                    <div style={{flex:1,height:28,background:'#1E3A5F',borderRadius:6,overflow:'hidden',position:'relative'}}>
                      <div style={{height:'100%',width:`${pct}%`,background:isLatest?'linear-gradient(90deg,#4D9FFF,#0055CC)':'linear-gradient(90deg,#334155,#475569)',borderRadius:6,transition:'width 0.8s ease',display:'flex',alignItems:'center',paddingLeft:8}}>
                        <span style={{fontSize:11,color:'white',fontWeight:600}}>{attempt.score}</span>
                      </div>
                    </div>
                    <div style={{fontSize:11,color:isLatest?'#4D9FFF':'#6B8FAF',fontWeight:isLatest?700:400,width:40,textAlign:'right'}}>{pct}%</div>
                  </div>
                );
              })}
            </div>
            <button onClick={()=>router.push('/dashboard/results/history')}
              style={{width:'100%',padding:14,background:'transparent',border:'1px solid #002D55',borderRadius:12,color:'#4D9FFF',fontSize:14,fontWeight:600,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>
              View All Results →
            </button>
          </div>
        )}

      </div>

      {/* ── BOTTOM ACTIONS ── */}
      <div style={{padding:'16px',display:'flex',gap:10,position:'sticky',bottom:0,background:'linear-gradient(0deg,#000A18 60%,transparent)',paddingTop:20}}>
        <button onClick={()=>router.push('/dashboard')}
          style={{flex:1,padding:14,background:'rgba(0,22,40,0.9)',border:'1px solid #002D55',borderRadius:12,color:'#6B8FAF',fontSize:14,fontWeight:600,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>
          Dashboard
        </button>
        <button onClick={()=>router.push('/dashboard/leaderboard')}
          style={{flex:1,padding:14,background:'linear-gradient(135deg,#4D9FFF,#0055CC)',border:'none',borderRadius:12,color:'white',fontSize:14,fontWeight:700,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>
          🏆 Leaderboard
        </button>
      </div>
    </div>
  );
}
