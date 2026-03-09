'use client';
import { useEffect, useState, useRef } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { getToken } from '@/lib/auth';

interface ExamInfo {
  _id: string;
  title: string;
  scheduledAt?: string;
  duration?: number;
  totalQuestions?: number;
  instructions?: string;
}

function useCountdown(target: string) {
  const [diff, setDiff] = useState(0);
  useEffect(() => {
    const calc = () => setDiff(Math.max(0, new Date(target).getTime() - Date.now()));
    calc();
    const id = setInterval(calc, 1000);
    return () => clearInterval(id);
  }, [target]);
  const h = Math.floor(diff / 3600000);
  const m = Math.floor((diff % 3600000) / 60000);
  const s = Math.floor((diff % 60000) / 1000);
  return { h, m, s, done: diff === 0 };
}

export default function WaitingRoomPage() {
  const { examId } = useParams<{ examId: string }>();
  const router = useRouter();
  const [exam, setExam] = useState<ExamInfo | null>(null);
  const [liveCount, setLiveCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState('');
  const token = getToken();

  // Fetch exam details
  useEffect(() => {
    if (!token) { router.push('/login'); return; }
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/exams/${examId}`, {
      headers: { Authorization: `Bearer ${token}` },
    }).then(r => r.json()).then(d => {
      setExam(d.exam || d);
      setLoading(false);
    }).catch(() => { setError('Exam details load nahi hue'); setLoading(false); });

    // Live student count via polling (Socket.io fallback)
    const poll = setInterval(() => {
      fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/exams/${examId}/live-count`, {
        headers: { Authorization: `Bearer ${token}` },
      }).then(r => r.json()).then(d => setLiveCount(d.count || 0)).catch(() => {});
    }, 5000);
    return () => clearInterval(poll);
  }, [examId, token, router]);

  const handleStart = async () => {
    setStarting(true);
    setError('');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/exams/${examId}/start-attempt`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.message || 'Start failed');
      const attemptId = data.attempt?._id || data.attemptId || data._id;
      router.push(`/dashboard/exams/${examId}/attempt?attemptId=${attemptId}`);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Start nahi hua');
      setStarting(false);
    }
  };

  const target = exam?.scheduledAt || new Date(Date.now() + 60000).toISOString();
  const { h, m, s, done } = useCountdown(target);
  const pct = exam?.scheduledAt
    ? Math.min(100, ((Date.now() - (new Date(exam.scheduledAt).getTime() - 600000)) / 600000) * 100)
    : 80;

  if (loading) return (
    <div style={{ display:'flex', alignItems:'center', justifyContent:'center', height:'100vh', background:'#000A18', color:'#4D9FFF', fontSize:18 }}>
      ⟳ Loading exam details...
    </div>
  );

  return (
    <div style={{ minHeight:'100vh', background:'#000A18', color:'#E8F4FF', fontFamily:'Inter,sans-serif', display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', padding:24, position:'relative', overflow:'hidden' }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600&display=swap');
        @keyframes pulse { 0%,100%{opacity:1}50%{opacity:0.5} }
        @keyframes float { 0%,100%{transform:translateY(0)}50%{transform:translateY(-10px)} }
        @keyframes fillBar { from{width:0} to{width:var(--w)} }
        .hex-bg { position:absolute; font-size:180px; color:rgba(77,159,255,0.04); pointer-events:none; }
      `}</style>

      {/* BG hexagons */}
      <div className="hex-bg" style={{ top:-40, left:-40 }}>⬡</div>
      <div className="hex-bg" style={{ bottom:-40, right:-40 }}>⬡</div>
      <div className="hex-bg" style={{ top:'40%', right:-60 }}>⬡</div>

      {/* PR Logo */}
      <div style={{ marginBottom:32, textAlign:'center', animation:'float 4s ease-in-out infinite' }}>
        <div style={{ fontFamily:'Playfair Display,serif', fontSize:28, color:'#4D9FFF', fontWeight:700, letterSpacing:2 }}>⬡ ProveRank</div>
      </div>

      {/* Exam Title */}
      <div style={{ fontFamily:'Playfair Display,serif', fontSize:26, fontWeight:700, textAlign:'center', marginBottom:8, maxWidth:500 }}>
        {exam?.title || 'Exam'}
      </div>
      <div style={{ color:'#6B8FAF', fontSize:13, marginBottom:40, letterSpacing:1 }}>Exam Waiting Room</div>

      {/* Live Counter */}
      <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:32, background:'rgba(77,159,255,0.1)', border:'1px solid rgba(77,159,255,0.3)', borderRadius:20, padding:'6px 18px' }}>
        <span style={{ width:8, height:8, borderRadius:'50%', background:'#4DF08E', display:'inline-block', animation:'pulse 1.5s infinite' }}/>
        <span style={{ fontSize:13, color:'#E8F4FF' }}>{liveCount} students online</span>
      </div>

      {/* Countdown Timer */}
      {!done ? (
        <div style={{ textAlign:'center', marginBottom:40 }}>
          <div style={{ color:'#6B8FAF', fontSize:12, letterSpacing:3, textTransform:'uppercase', marginBottom:12 }}>Exam Starts In</div>
          <div style={{ display:'flex', gap:16, justifyContent:'center' }}>
            {[{ v: h, l: 'HRS' }, { v: m, l: 'MIN' }, { v: s, l: 'SEC' }].map(({ v, l }) => (
              <div key={l} style={{ textAlign:'center' }}>
                <div style={{ background:'#001628', border:'2px solid #4D9FFF', borderRadius:12, width:72, height:72, display:'flex', alignItems:'center', justifyContent:'center', fontSize:32, fontWeight:700, color:'#4D9FFF', boxShadow:'0 0 20px rgba(77,159,255,0.3)' }}>
                  {String(v).padStart(2, '0')}
                </div>
                <div style={{ fontSize:9, color:'#6B8FAF', marginTop:4, letterSpacing:2 }}>{l}</div>
              </div>
            ))}
          </div>
        </div>
      ) : (
        <div style={{ color:'#4DF08E', fontSize:18, fontWeight:700, marginBottom:40, animation:'pulse 1s infinite' }}>🟢 Exam is Live!</div>
      )}

      {/* Progress Bar */}
      <div style={{ width:'100%', maxWidth:440, marginBottom:40 }}>
        <div style={{ height:4, background:'#002D55', borderRadius:2, overflow:'hidden' }}>
          <div style={{ height:'100%', width:`${pct}%`, background:'linear-gradient(90deg,#4D9FFF,#4DF08E)', borderRadius:2, transition:'width 1s ease' }}/>
        </div>
        <div style={{ display:'flex', justifyContent:'space-between', marginTop:6, fontSize:11, color:'#6B8FAF' }}>
          <span>Waiting</span><span>Starting</span>
        </div>
      </div>

      {/* Exam Info Cards */}
      <div style={{ display:'flex', gap:16, marginBottom:40, flexWrap:'wrap', justifyContent:'center' }}>
        {[
          { icon:'📝', label:'Questions', val: exam?.totalQuestions || 180 },
          { icon:'⏱️', label:'Duration', val: `${exam?.duration || 180} min` },
          { icon:'🎯', label:'Marking', val: '+4 / -1' },
        ].map(({ icon, label, val }) => (
          <div key={label} style={{ background:'#001628', border:'1px solid #002D55', borderRadius:12, padding:'12px 20px', textAlign:'center', minWidth:100 }}>
            <div style={{ fontSize:22, marginBottom:4 }}>{icon}</div>
            <div style={{ fontSize:18, fontWeight:700, color:'#4D9FFF' }}>{val}</div>
            <div style={{ fontSize:11, color:'#6B8FAF', marginTop:2 }}>{label}</div>
          </div>
        ))}
      </div>

      {/* Instructions */}
      {exam?.instructions && (
        <div style={{ background:'rgba(77,159,255,0.06)', border:'1px solid #002D55', borderRadius:12, padding:16, maxWidth:440, width:'100%', marginBottom:32, fontSize:13, color:'#B0C4D8', lineHeight:1.7 }}>
          <div style={{ color:'#4D9FFF', fontWeight:600, marginBottom:8 }}>📋 Instructions</div>
          {exam.instructions}
        </div>
      )}

      {error && <div style={{ color:'#FF6B6B', marginBottom:16, fontSize:13 }}>⚠️ {error}</div>}

      {/* Start Button */}
      <button
        onClick={handleStart}
        disabled={starting}
        style={{ background: starting ? '#002D55' : 'linear-gradient(135deg,#4D9FFF,#0055CC)', color:'white', border:'none', borderRadius:12, padding:'16px 48px', fontSize:16, fontWeight:700, cursor: starting ? 'not-allowed' : 'pointer', letterSpacing:1, boxShadow:'0 0 30px rgba(77,159,255,0.4)', transition:'all 0.3s' }}>
        {starting ? '⟳ Starting...' : '▶ Start Exam Now'}
      </button>

      <div style={{ marginTop:20, fontSize:12, color:'#6B8FAF', textAlign:'center' }}>
        Exam shuru hone ke baad tab switch ya fullscreen exit karne par warning milegi
      </div>
    </div>
  );
}
