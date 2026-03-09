'use client';
import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { getToken } from '@/lib/auth';
import PRLogo from '@/components/PRLogo';

interface Result {
  score?: number;
  maxScore?: number;
  rank?: number;
  percentile?: number;
  totalCorrect?: number;
  totalIncorrect?: number;
  totalUnattempted?: number;
  examTitle?: string;
  subjectStats?: Record<string, { score: number; correct: number; incorrect: number; total: number }>;
}

export default function ResultPage() {
  const { attemptId } = useParams<{ attemptId: string }>();
  const router = useRouter();
  const token = getToken();
  const [result, setResult] = useState<Result | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!token) { router.push('/login'); return; }
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/results/${attemptId}`, {
      headers: { Authorization: `Bearer ${token}` },
    }).then(r => r.json()).then(d => {
      setResult(d.result || d);
      setLoading(false);
    }).catch(() => {
      setError('Result load nahi hua');
      setLoading(false);
    });
  }, [attemptId, token, router]);

  if (loading) return (
    <div style={{ display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', height:'100vh', background:'#000A18', color:'#4D9FFF', gap:16 }}>
      <div style={{ fontSize:48, animation:'spin 1s linear infinite' }}>⟳</div>
      <div style={{ fontSize:16 }}>Result calculate ho raha hai...</div>
      <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
    </div>
  );

  if (error) return (
    <div style={{ display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', height:'100vh', background:'#000A18', color:'#E8F4FF', gap:16 }}>
      <div style={{ fontSize:48 }}>⚠️</div>
      <div>{error}</div>
      <button onClick={() => router.push('/dashboard')} style={{ background:'#4D9FFF', color:'white', border:'none', borderRadius:8, padding:'10px 24px', cursor:'pointer', fontWeight:600 }}>Dashboard</button>
    </div>
  );

  const pct = result?.maxScore ? Math.round(((result.score || 0) / result.maxScore) * 100) : 0;

  return (
    <div style={{ minHeight:'100vh', background:'#000A18', color:'#E8F4FF', fontFamily:'Inter,sans-serif', padding:24 }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600&display=swap');
        @keyframes fadeIn { from{opacity:0;transform:translateY(20px)} to{opacity:1;transform:translateY(0)} }
        @keyframes countUp { from{opacity:0} to{opacity:1} }
        .card { background:#001628; border:1px solid #002D55; border-radius:14px; padding:20px; animation:fadeIn 0.5s ease forwards; }
      `}</style>

      <div style={{ maxWidth:560, margin:'0 auto' }}>
        {/* Header */}
        <div style={{ textAlign:'center', marginBottom:32, paddingTop:16 }}>
          <PRLogo size={48} showName horizontal nameSize={22} />
        </div>

        {/* Hero Score Banner */}
        <div style={{ background:'linear-gradient(135deg,#001E3C,#003366)', border:'1px solid #4D9FFF', borderRadius:20, padding:32, textAlign:'center', marginBottom:20, boxShadow:'0 0 40px rgba(77,159,255,0.15)' }}>
          <div style={{ fontSize:13, color:'#6B8FAF', letterSpacing:3, textTransform:'uppercase', marginBottom:16 }}>
            {result?.examTitle || 'Exam Result'}
          </div>
          {/* Big Score */}
          <div style={{ fontSize:72, fontWeight:900, color:'#4D9FFF', lineHeight:1, marginBottom:4, fontVariantNumeric:'tabular-nums' }}>
            {result?.score ?? '--'}
          </div>
          <div style={{ fontSize:18, color:'#6B8FAF', marginBottom:24 }}>
            out of {result?.maxScore ?? 720}
          </div>
          {/* Stats row */}
          <div style={{ display:'grid', gridTemplateColumns:'repeat(3,1fr)', gap:12 }}>
            {[
              { label:'Rank', val: result?.rank ? `#${result.rank}` : '--', color:'#F59E0B' },
              { label:'Percentile', val: result?.percentile ? `${Number(result.percentile).toFixed(1)}%` : '--', color:'#4D9FFF' },
              { label:'Accuracy', val: result?.maxScore ? `${pct}%` : '--', color:'#22C55E' },
            ].map(({ label, val, color }) => (
              <div key={label} style={{ background:'rgba(0,0,0,0.3)', borderRadius:10, padding:'12px 8px' }}>
                <div style={{ fontSize:22, fontWeight:700, color }}>{val}</div>
                <div style={{ fontSize:11, color:'#6B8FAF', marginTop:2 }}>{label}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Correct / Wrong / Skip */}
        <div className="card" style={{ marginBottom:16 }}>
          <div style={{ fontWeight:700, marginBottom:14, fontSize:15 }}>📊 Answer Summary</div>
          <div style={{ display:'grid', gridTemplateColumns:'repeat(3,1fr)', gap:12 }}>
            {[
              { label:'Correct', val: result?.totalCorrect ?? '--', color:'#22C55E', bg:'rgba(34,197,94,0.1)' },
              { label:'Incorrect', val: result?.totalIncorrect ?? '--', color:'#EF4444', bg:'rgba(239,68,68,0.1)' },
              { label:'Skipped', val: result?.totalUnattempted ?? '--', color:'#6B8FAF', bg:'rgba(107,143,175,0.1)' },
            ].map(({ label, val, color, bg }) => (
              <div key={label} style={{ background:bg, borderRadius:10, padding:'14px 10px', textAlign:'center' }}>
                <div style={{ fontSize:26, fontWeight:700, color }}>{val}</div>
                <div style={{ fontSize:12, color:'#6B8FAF', marginTop:2 }}>{label}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Subject stats */}
        {result?.subjectStats && (
          <div className="card" style={{ marginBottom:24 }}>
            <div style={{ fontWeight:700, marginBottom:14, fontSize:15 }}>📚 Subject-wise Performance</div>
            {Object.entries(result.subjectStats).map(([sub, stat]) => (
              <div key={sub} style={{ marginBottom:14 }}>
                <div style={{ display:'flex', justifyContent:'space-between', marginBottom:6, fontSize:13 }}>
                  <span style={{ color:'#E8F4FF', fontWeight:500 }}>{sub}</span>
                  <span style={{ color:'#4D9FFF', fontWeight:700 }}>{stat.score}/{stat.total * 4}</span>
                </div>
                <div style={{ height:6, background:'#002D55', borderRadius:3, overflow:'hidden' }}>
                  <div style={{ height:'100%', width:`${stat.total > 0 ? (stat.correct / stat.total) * 100 : 0}%`, background:'#4D9FFF', borderRadius:3 }}/>
                </div>
                <div style={{ display:'flex', gap:12, marginTop:4, fontSize:11, color:'#6B8FAF' }}>
                  <span>✅ {stat.correct}</span>
                  <span>❌ {stat.incorrect}</span>
                  <span>⬜ {stat.total - stat.correct - stat.incorrect}</span>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Actions */}
        <div style={{ display:'flex', gap:12 }}>
          <button onClick={() => router.push('/dashboard')}
            style={{ flex:1, padding:'14px', borderRadius:10, border:'1px solid #002D55', background:'#001628', color:'#E8F4FF', cursor:'pointer', fontWeight:600, fontSize:14 }}>
            🏠 Dashboard
          </button>
          <button onClick={() => router.push('/dashboard/exams')}
            style={{ flex:1, padding:'14px', borderRadius:10, border:'none', background:'linear-gradient(135deg,#4D9FFF,#0055CC)', color:'white', cursor:'pointer', fontWeight:700, fontSize:14 }}>
            📝 More Exams
          </button>
        </div>
      </div>
    </div>
  );
}
