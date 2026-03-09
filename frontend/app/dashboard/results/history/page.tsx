'use client';
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { getToken } from '@/lib/auth';

const MOCK_HISTORY = [
  { attemptId:'att001', examTitle:'NEET Mock Test — Series 5', date:'2025-01-15', score:540, maxScore:720, rank:42, percentile:96.6, correct:135, wrong:30, status:'completed' },
  { attemptId:'att002', examTitle:'NEET Mock Test — Series 4', date:'2025-01-10', score:510, maxScore:720, rank:68, percentile:94.5, correct:128, wrong:32, status:'completed' },
  { attemptId:'att003', examTitle:'NEET Mock Test — Series 3', date:'2025-01-05', score:480, maxScore:720, rank:95, percentile:92.4, correct:120, wrong:36, status:'completed' },
  { attemptId:'att004', examTitle:'NEET Mock Test — Series 2', date:'2024-12-28', score:420, maxScore:720, rank:145, percentile:88.4, correct:105, wrong:42, status:'completed' },
  { attemptId:'att005', examTitle:'NEET Mock Test — Series 1', date:'2024-12-20', score:380, maxScore:720, rank:210, percentile:83.2, correct:95, wrong:48, status:'completed' },
];

export default function ResultHistoryPage() {
  const router = useRouter();
  const [history, setHistory] = useState<typeof MOCK_HISTORY>([]);
  const [loading, setLoading] = useState(true);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    if (!getToken()) { router.push('/login'); return; }
    const fetchHistory = async () => {
      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/results/history`, {
          headers: { Authorization: `Bearer ${getToken()}` }
        });
        if (res.ok) { const data = await res.json(); setHistory(data); }
        else setHistory(MOCK_HISTORY);
      } catch { setHistory(MOCK_HISTORY); }
      finally { setLoading(false); }
    };
    fetchHistory();
  }, [router]);

  if (!mounted || loading) return (
    <div style={{minHeight:'100vh',background:'#000A18',display:'flex',alignItems:'center',justifyContent:'center',color:'#4D9FFF',fontSize:16}}>
      ⟳ Loading history...
    </div>
  );

  const avgScore = Math.round(history.reduce((s,h)=>s+h.score,0)/history.length);
  const bestRank = Math.min(...history.map(h=>h.rank));
  const trend = history.length>1 ? (history[0].score > history[history.length-1].score ? '📈' : '📉') : '—';

  return (
    <div style={{minHeight:'100vh',background:'#000A18',fontFamily:'Inter,sans-serif',color:'#E8F4FF'}}>
      <style>{`@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600&display=swap');@keyframes fadeUp{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:translateY(0)}}`}</style>

      {/* Header */}
      <div style={{background:'#001628',borderBottom:'1px solid #002D55',padding:'14px 16px',display:'flex',alignItems:'center',gap:12,position:'sticky',top:0,zIndex:50}}>
        <button onClick={()=>router.push('/dashboard')} style={{background:'rgba(77,159,255,0.1)',border:'1px solid #002D55',borderRadius:8,color:'#4D9FFF',padding:'6px 12px',cursor:'pointer',fontSize:13,fontFamily:'Inter,sans-serif'}}>← Back</button>
        <div style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:'#E8F4FF'}}>📋 Result History</div>
      </div>

      <div style={{padding:'16px'}}>
        {/* Summary Cards */}
        <div style={{display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:10,marginBottom:20,animation:'fadeUp 0.4s ease'}}>
          {[
            {l:'Avg Score',v:avgScore,sub:`/ ${history[0]?.maxScore||720}`,c:'#4D9FFF'},
            {l:'Best Rank',v:`#${bestRank}`,sub:'All time',c:'#F59E0B'},
            {l:'Trend',v:trend,sub:`${history.length} attempts`,c:'#22C55E'},
          ].map(({l,v,sub,c})=>(
            <div key={l} style={{background:'#001628',border:'1px solid #002D55',borderRadius:12,padding:'14px 10px',textAlign:'center'}}>
              <div style={{fontSize:11,color:'#6B8FAF',marginBottom:4}}>{l}</div>
              <div style={{fontSize:20,fontWeight:700,color:c,fontFamily:'Playfair Display,serif'}}>{v}</div>
              <div style={{fontSize:10,color:'#3A5A7A'}}>{sub}</div>
            </div>
          ))}
        </div>

        {/* History List */}
        <div style={{display:'flex',flexDirection:'column',gap:10}}>
          {history.map((attempt,i)=>{
            const pct = Math.round((attempt.score/attempt.maxScore)*100);
            const scoreColor = pct>=75?'#22C55E':pct>=50?'#F59E0B':'#EF4444';
            return (
              <div key={attempt.attemptId}
                onClick={()=>router.push(`/dashboard/results/${attempt.attemptId}`)}
                style={{background:'#001628',border:'1px solid #002D55',borderRadius:14,padding:'16px',cursor:'pointer',transition:'border 0.2s',animation:`fadeUp ${0.3+i*0.05}s ease`}}>
                <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:10}}>
                  <div style={{flex:1,marginRight:12}}>
                    <div style={{fontSize:13,fontWeight:600,color:'#E8F4FF',marginBottom:3}}>{attempt.examTitle}</div>
                    <div style={{fontSize:11,color:'#6B8FAF'}}>{attempt.date}</div>
                  </div>
                  <div style={{textAlign:'right'}}>
                    <div style={{fontSize:20,fontWeight:700,color:scoreColor,fontFamily:'Playfair Display,serif'}}>{attempt.score}</div>
                    <div style={{fontSize:10,color:'#6B8FAF'}}>/ {attempt.maxScore}</div>
                  </div>
                </div>
                <div style={{height:4,background:'#1E3A5F',borderRadius:2,marginBottom:10,overflow:'hidden'}}>
                  <div style={{height:'100%',width:`${pct}%`,background:`linear-gradient(90deg,${scoreColor},${scoreColor}88)`,borderRadius:2}}/>
                </div>
                <div style={{display:'flex',justifyContent:'space-between',fontSize:11,color:'#6B8FAF'}}>
                  <span>Rank #{attempt.rank}</span>
                  <span>{attempt.percentile}%ile</span>
                  <span>✅ {attempt.correct} ❌ {attempt.wrong}</span>
                  <span style={{color:'#4D9FFF'}}>View →</span>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
