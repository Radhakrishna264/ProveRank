'use client';
import { useState, useEffect } from 'react';
import { getToken } from '@/lib/auth';

const MOCK_RESULTS = [
  { student:'Arjun Sharma', exam:'NEET Mock Series 5', score:698, maxScore:720, rank:1, date:'2025-01-15', percentile:99.8 },
  { student:'Priya Singh', exam:'NEET Mock Series 5', score:685, maxScore:720, rank:2, date:'2025-01-15', percentile:99.5 },
  { student:'Rahul Verma', exam:'NEET Mock Series 5', score:672, maxScore:720, rank:3, date:'2025-01-15', percentile:99.1 },
  { student:'Amit Kumar', exam:'NEET Mock Series 5', score:540, maxScore:720, rank:42, date:'2025-01-15', percentile:96.6 },
  { student:'Sneha Patel', exam:'NEET Mock Series 4', score:480, maxScore:720, rank:95, date:'2025-01-10', percentile:87.4 },
];

export default function AdminResultsPage() {
  const [results, setResults] = useState<typeof MOCK_RESULTS>([]);
  const [examFilter, setExamFilter] = useState('all');
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    const fetch_ = async () => {
      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/admin/results`, {
          headers: { Authorization: `Bearer ${getToken()}` }
        });
        if (res.ok) setResults(await res.json());
        else setResults(MOCK_RESULTS);
      } catch { setResults(MOCK_RESULTS); }
    };
    fetch_();
  }, []);

  if (!mounted) return null;

  const avgScore = results.length ? Math.round(results.reduce((s,r)=>s+r.score,0)/results.length) : 0;

  return (
    <div style={{padding:'20px 16px',color:'#E8F4FF'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:700,color:'#E8F4FF',margin:'0 0 16px'}}>📈 Results Overview</h1>

      {/* Summary */}
      <div style={{display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:10,marginBottom:16}}>
        {[{l:'Total Results',v:results.length,c:'#4D9FFF'},{l:'Avg Score',v:avgScore,c:'#22C55E'},{l:'Top Score',v:Math.max(...results.map(r=>r.score)),c:'#F59E0B'}].map(({l,v,c})=>(
          <div key={l} style={{background:'#001628',border:'1px solid #002D55',borderRadius:12,padding:'12px',textAlign:'center'}}>
            <div style={{fontSize:20,fontWeight:700,color:c,fontFamily:'Playfair Display,serif'}}>{v}</div>
            <div style={{fontSize:10,color:'#6B8FAF',marginTop:2}}>{l}</div>
          </div>
        ))}
      </div>

      {/* Filter */}
      <select value={examFilter} onChange={e=>setExamFilter(e.target.value)}
        style={{width:'100%',padding:'10px 12px',background:'#001628',border:'1px solid #002D55',borderRadius:10,color:'#6B8FAF',fontSize:12,outline:'none',fontFamily:'Inter,sans-serif',marginBottom:12}}>
        <option value="all">All Exams</option>
        <option value="NEET Mock Series 5">NEET Mock Series 5</option>
        <option value="NEET Mock Series 4">NEET Mock Series 4</option>
      </select>

      {/* Results Table */}
      <div style={{display:'flex',flexDirection:'column',gap:8}}>
        {results.filter(r=>examFilter==='all'||r.exam===examFilter).map((r,i)=>{
          const pct = Math.round((r.score/r.maxScore)*100);
          const c = pct>=75?'#22C55E':pct>=50?'#F59E0B':'#EF4444';
          return (
            <div key={i} style={{background:'#001628',border:'1px solid #002D55',borderRadius:12,padding:'14px'}}>
              <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:8}}>
                <div>
                  <div style={{fontSize:13,fontWeight:600,color:'#E8F4FF'}}>{r.student}</div>
                  <div style={{fontSize:11,color:'#6B8FAF'}}>{r.exam} · {r.date}</div>
                </div>
                <div style={{textAlign:'right'}}>
                  <div style={{fontSize:18,fontWeight:700,color:c,fontFamily:'Playfair Display,serif'}}>{r.score}</div>
                  <div style={{fontSize:10,color:'#6B8FAF'}}>#{r.rank} · {r.percentile}%ile</div>
                </div>
              </div>
              <div style={{height:4,background:'#1E3A5F',borderRadius:2,overflow:'hidden'}}>
                <div style={{height:'100%',width:`${pct}%`,background:`linear-gradient(90deg,${c},${c}88)`,borderRadius:2}}/>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
