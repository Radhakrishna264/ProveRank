'use client';
import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import { getToken } from '@/lib/auth';
import Link from 'next/link';

function BigCountdown({ targetDate }: { targetDate: string }) {
  const [time,   setTime]   = useState({ d:0, h:0, m:0, s:0 });
  const [urgent, setUrgent] = useState(false);

  useEffect(() => {
    const calc = () => {
      const diff = new Date(targetDate).getTime() - Date.now();
      if (diff <= 0) { setTime({ d:0, h:0, m:0, s:0 }); return; }
      setUrgent(diff < 3600000);
      setTime({ d:Math.floor(diff/86400000), h:Math.floor((diff%86400000)/3600000), m:Math.floor((diff%3600000)/60000), s:Math.floor((diff%60000)/1000) });
    };
    calc(); const id = setInterval(calc,1000); return () => clearInterval(id);
  }, [targetDate]);

  const color = urgent ? '#FF4D4D' : '#4D9FFF';
  const glow  = urgent ? 'rgba(255,77,77,0.3)' : 'rgba(77,159,255,0.3)';

  return (
    <div style={{ display:'flex', gap:20, justifyContent:'center', flexWrap:'wrap' }}>
      {[{v:time.d,l:'DAYS',max:30},{v:time.h,l:'HOURS',max:24},{v:time.m,l:'MINUTES',max:60},{v:time.s,l:'SECONDS',max:60}].map(({ v, l, max }) => (
        <div key={l} style={{ textAlign:'center' }}>
          <div style={{ position:'relative', width:100, height:100, margin:'0 auto 8px' }}>
            <svg width={100} height={100} style={{ transform:'rotate(-90deg)' }}>
              <circle cx={50} cy={50} r={42} fill="none" stroke={`${color}22`} strokeWidth={6}/>
              <circle cx={50} cy={50} r={42} fill="none" stroke={color} strokeWidth={6}
                strokeDasharray={`${(v/max)*263.9} 263.9`} strokeLinecap="round"
                style={{ transition:'stroke-dasharray 0.5s ease', filter:`drop-shadow(0 0 6px ${glow})` }}/>
            </svg>
            <div style={{ position:'absolute', inset:0, display:'flex', alignItems:'center', justifyContent:'center', fontSize:28, fontWeight:700, color, fontVariantNumeric:'tabular-nums' }}>
              {String(v).padStart(2,'0')}
            </div>
          </div>
          <div style={{ fontSize:10, color:'var(--muted)', letterSpacing:2, fontWeight:600 }}>{l}</div>
        </div>
      ))}
    </div>
  );
}

export default function ExamCountdownPage() {
  const params  = useParams();
  const examId  = params?.examId as string;
  const [exam,    setExam]    = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [copied,  setCopied]  = useState(false);

  useEffect(() => {
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/exams/${examId}`, { headers:{ Authorization:`Bearer ${getToken()}` } })
      .then(r => r.json()).then(d => { setExam(d); setLoading(false); }).catch(() => setLoading(false));
  }, [examId]);

  const copyLink = () => { navigator.clipboard.writeText(window.location.href); setCopied(true); setTimeout(() => setCopied(false), 2000); };

  if (loading) return <div style={{ textAlign:'center', color:'var(--muted)', padding:60 }}>Loading...</div>;
  if (!exam)   return <div style={{ textAlign:'center', color:'var(--muted)', padding:60 }}>Exam not found</div>;

  const isLive = exam.status === 'active';
  const isDone = exam.status === 'completed';

  return (
    <div style={{ maxWidth:700, margin:'0 auto', textAlign:'center' }}>
      <div style={{ background:'linear-gradient(135deg,#000A18,#001A3A)', border:'1px solid var(--border)', borderRadius:20, padding:'40px 32px', marginBottom:24, position:'relative', overflow:'hidden' }}>
        <div style={{ position:'absolute', top:-20, right:-20, fontSize:120, opacity:0.04, color:'var(--primary)' }}>⬡</div>
        {exam.seriesName && <div style={{ fontSize:12, color:'var(--primary)', marginBottom:8, letterSpacing:1, textTransform:'uppercase' }}>{exam.seriesName}</div>}
        <h1 style={{ fontFamily:'Playfair Display,serif', fontSize:28, color:'var(--text)', marginBottom:8, lineHeight:1.3 }}>{exam.title}</h1>
        <div style={{ display:'flex', gap:16, justifyContent:'center', flexWrap:'wrap', marginBottom:32, color:'var(--muted)', fontSize:13 }}>
          <span>📅 {new Date(exam.scheduledFor).toLocaleString('en-IN')}</span>
          <span>⏱️ {exam.duration} min</span>
          <span>📊 {exam.totalMarks} marks</span>
          <span>❓ {exam.totalQuestions} questions</span>
        </div>
        {isLive ? (
          <div>
            <div style={{ fontSize:18, color:'#4DFF90', fontWeight:700, marginBottom:20, animation:'pulse 1s infinite' }}>🔴 EXAM IS LIVE NOW!</div>
            <Link href={`/exam/${examId}/attempt`}>
              <button style={{ background:'#4DFF90', color:'#000A18', border:'none', borderRadius:12, padding:'14px 40px', cursor:'pointer', fontWeight:700, fontSize:18 }}>🚀 Join Now</button>
            </Link>
          </div>
        ) : isDone ? (
          <div>
            <div style={{ fontSize:16, color:'var(--muted)', marginBottom:16 }}>✅ Exam Completed</div>
            <Link href={`/dashboard/results?exam=${examId}`}>
              <button style={{ background:'var(--primary)', color:'#000A18', border:'none', borderRadius:10, padding:'12px 32px', cursor:'pointer', fontWeight:600 }}>View Result →</button>
            </Link>
          </div>
        ) : (
          <BigCountdown targetDate={exam.scheduledFor}/>
        )}
      </div>
      {exam.instructions?.length > 0 && (
        <div style={{ background:'var(--card)', border:'1px solid var(--border)', borderRadius:14, padding:20, marginBottom:16, textAlign:'left' }}>
          <h3 style={{ fontFamily:'Playfair Display,serif', fontSize:16, color:'var(--text)', marginBottom:12 }}>📋 Instructions</h3>
          <ul style={{ paddingLeft:20, display:'flex', flexDirection:'column', gap:8 }}>
            {exam.instructions.map((inst: string, i: number) => <li key={i} style={{ fontSize:13, color:'var(--muted)', lineHeight:1.6 }}>{inst}</li>)}
          </ul>
        </div>
      )}
      <div style={{ display:'flex', gap:12, justifyContent:'center' }}>
        <button onClick={copyLink} style={{ background:'var(--card)', border:'1px solid var(--border)', color:'var(--text)', borderRadius:8, padding:'8px 18px', cursor:'pointer', fontSize:13 }}>
          {copied ? '✅ Copied!' : '🔗 Copy Link'}
        </button>
        <Link href="/dashboard/exams">
          <button style={{ background:'none', border:'1px solid var(--border)', color:'var(--muted)', borderRadius:8, padding:'8px 18px', cursor:'pointer', fontSize:13 }}>← Back</button>
        </Link>
      </div>
    </div>
  );
}
