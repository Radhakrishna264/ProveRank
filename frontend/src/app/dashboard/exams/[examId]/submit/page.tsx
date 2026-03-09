'use client';
import { useEffect, useState } from 'react';
import { useParams, useSearchParams, useRouter } from 'next/navigation';
import { getToken } from '@/lib/auth';

export default function SubmitSummaryPage() {
  const { examId } = useParams<{ examId: string }>();
  const searchParams = useSearchParams();
  const attemptId = searchParams.get('attemptId') || '';
  const isAuto = searchParams.get('auto') === 'true';
  const router = useRouter();
  const token = getToken();

  const [attempt, setAttempt] = useState<{
    examTitle?: string;
    totalQuestions?: number;
    answered?: number;
    notAnswered?: number;
    marked?: number;
    timeRemaining?: number;
    subjectStats?: Record<string, { answered: number; total: number }>;
  } | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!token) { router.push('/login'); return; }
    // Fetch navigation summary
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/attempts/${attemptId}/navigation`, {
      headers: { Authorization: `Bearer ${token}` },
    }).then(r => r.json()).then(d => {
      const nav = d.navigation || d;
      const questions = nav.questions || [];
      const answered = questions.filter((q: { status: string }) => q.status === 'answered').length;
      const marked = questions.filter((q: { status: string }) => q.status === 'marked').length;
      const total = questions.length;
      // Subject-wise breakdown
      const subjectMap: Record<string, { answered: number; total: number }> = {};
      questions.forEach((q: { subject?: string; status: string }) => {
        const sub = q.subject || 'General';
        if (!subjectMap[sub]) subjectMap[sub] = { answered: 0, total: 0 };
        subjectMap[sub].total++;
        if (q.status === 'answered') subjectMap[sub].answered++;
      });
      setAttempt({
        examTitle: d.examTitle || nav.examTitle || 'Exam',
        totalQuestions: total,
        answered,
        notAnswered: total - answered - marked,
        marked,
        timeRemaining: d.timeRemaining || 0,
        subjectStats: subjectMap,
      });
      setLoading(false);
      // If auto-submit, submit immediately
      if (isAuto) { handleSubmit(true); }
    }).catch(() => {
      setAttempt({ totalQuestions: 180, answered: 0, notAnswered: 180, marked: 0 });
      setLoading(false);
    });
  }, [attemptId, token, isAuto, router]);

  const handleSubmit = async (auto = false) => {
    if (submitting || submitted) return;
    setSubmitting(true);
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/attempts/${attemptId}/submit`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token || ''}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ autoSubmit: auto }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.message || 'Submit failed');
      setSubmitted(true);
      setTimeout(() => {
        router.push(`/dashboard/results/${attemptId}`);
      }, 2000);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Submit nahi hua');
      setSubmitting(false);
    }
  };

  if (loading) return (
    <div style={{ display:'flex', alignItems:'center', justifyContent:'center', height:'100vh', background:'#F8FAFC', fontSize:16, color:'#334155' }}>
      ⟳ Loading summary...
    </div>
  );

  if (submitted) return (
    <div style={{ display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', height:'100vh', background:'#F0FDF4', gap:20 }}>
      <div style={{ fontSize:64 }}>🎉</div>
      <div style={{ fontSize:24, fontWeight:700, color:'#15803D' }}>Exam Submitted!</div>
      <div style={{ color:'#16A34A' }}>Result page par ja rahe hain...</div>
      <div style={{ width:200, height:4, background:'#BBF7D0', borderRadius:2, overflow:'hidden' }}>
        <div style={{ height:'100%', background:'#22C55E', animation:'expand 2s linear forwards', borderRadius:2 }}/>
      </div>
      <style>{`@keyframes expand { from{width:0} to{width:100%} }`}</style>
    </div>
  );

  const total = attempt?.totalQuestions || 0;
  const answered = attempt?.answered || 0;
  const notAnswered = attempt?.notAnswered || 0;
  const marked = attempt?.marked || 0;

  return (
    <div style={{ minHeight:'100vh', background:'#F8FAFC', fontFamily:'Inter,sans-serif', padding:24 }}>
      <style>{`@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600&display=swap');`}</style>

      <div style={{ maxWidth:600, margin:'0 auto' }}>
        {/* Header */}
        <div style={{ textAlign:'center', marginBottom:32 }}>
          <div style={{ fontFamily:'Playfair Display,serif', fontSize:24, fontWeight:700, color:'#0F172A', marginBottom:4 }}>
            📤 Submit Exam
          </div>
          <div style={{ color:'#64748B', fontSize:14 }}>{attempt?.examTitle || 'Exam'}</div>
          {isAuto && (
            <div style={{ marginTop:8, background:'#FEF2F2', border:'1px solid #FCA5A5', borderRadius:8, padding:'8px 16px', color:'#DC2626', fontSize:13, fontWeight:600 }}>
              ⚠️ Auto-submit triggered (3 warnings exceeded)
            </div>
          )}
        </div>

        {/* S2: Stats Summary */}
        <div style={{ display:'grid', gridTemplateColumns:'repeat(3,1fr)', gap:16, marginBottom:24 }}>
          {[
            { icon:'✅', label:'Answered', val: answered, color:'#22C55E', bg:'#F0FDF4', border:'#BBF7D0' },
            { icon:'❌', label:'Unanswered', val: notAnswered, color:'#EF4444', bg:'#FEF2F2', border:'#FCA5A5' },
            { icon:'🔖', label:'Marked', val: marked, color:'#A855F7', bg:'#FAF5FF', border:'#DDD6FE' },
          ].map(({ icon, label, val, color, bg, border }) => (
            <div key={label} style={{ background:bg, border:`1px solid ${border}`, borderRadius:14, padding:'20px 16px', textAlign:'center' }}>
              <div style={{ fontSize:28 }}>{icon}</div>
              <div style={{ fontSize:32, fontWeight:700, color, margin:'4px 0' }}>{val}</div>
              <div style={{ fontSize:12, color:'#64748B' }}>{label}</div>
            </div>
          ))}
        </div>

        {/* Progress bar */}
        <div style={{ background:'white', borderRadius:14, padding:20, marginBottom:24, border:'1px solid #E2E8F0' }}>
          <div style={{ display:'flex', justifyContent:'space-between', marginBottom:8, fontSize:13, color:'#475569' }}>
            <span>Completion</span>
            <span style={{ fontWeight:700 }}>{total > 0 ? Math.round((answered / total) * 100) : 0}%</span>
          </div>
          <div style={{ height:8, background:'#F1F5F9', borderRadius:4, overflow:'hidden' }}>
            <div style={{ height:'100%', width:`${total > 0 ? (answered / total) * 100 : 0}%`, background:'linear-gradient(90deg,#4D9FFF,#22C55E)', borderRadius:4, transition:'width 0.5s' }}/>
          </div>
          <div style={{ marginTop:8, fontSize:12, color:'#94A3B8', textAlign:'right' }}>
            {answered} of {total} answered
          </div>
        </div>

        {/* Subject-wise table */}
        {attempt?.subjectStats && Object.keys(attempt.subjectStats).length > 0 && (
          <div style={{ background:'white', borderRadius:14, border:'1px solid #E2E8F0', overflow:'hidden', marginBottom:24 }}>
            <div style={{ padding:'14px 20px', borderBottom:'1px solid #F1F5F9', fontWeight:700, fontSize:14, color:'#0F172A' }}>
              📊 Subject-wise Summary
            </div>
            <table style={{ width:'100%', borderCollapse:'collapse' }}>
              <thead>
                <tr style={{ background:'#F8FAFC' }}>
                  {['Subject', 'Total', 'Answered', 'Status'].map(h => (
                    <th key={h} style={{ padding:'10px 16px', textAlign:'left', fontSize:12, fontWeight:600, color:'#475569', borderBottom:'1px solid #E2E8F0' }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {Object.entries(attempt.subjectStats).map(([sub, stat]) => (
                  <tr key={sub}>
                    <td style={{ padding:'12px 16px', fontSize:14, color:'#334155', fontWeight:500 }}>{sub}</td>
                    <td style={{ padding:'12px 16px', fontSize:14, color:'#64748B' }}>{stat.total}</td>
                    <td style={{ padding:'12px 16px', fontSize:14, color:'#22C55E', fontWeight:600 }}>{stat.answered}</td>
                    <td style={{ padding:'12px 16px' }}>
                      <div style={{ height:6, background:'#F1F5F9', borderRadius:3, overflow:'hidden', width:80 }}>
                        <div style={{ height:'100%', width:`${stat.total > 0 ? (stat.answered / stat.total) * 100 : 0}%`, background:'#4D9FFF', borderRadius:3 }}/>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Time remaining */}
        {(attempt?.timeRemaining || 0) > 0 && (
          <div style={{ background:'#FFFBEB', border:'1px solid #FDE68A', borderRadius:12, padding:'12px 20px', marginBottom:24, display:'flex', alignItems:'center', gap:10 }}>
            <span style={{ fontSize:20 }}>⏱️</span>
            <div>
              <div style={{ fontSize:13, fontWeight:600, color:'#92400E' }}>Time Remaining</div>
              <div style={{ fontSize:12, color:'#B45309' }}>
                {Math.floor((attempt?.timeRemaining || 0) / 60)}m {(attempt?.timeRemaining || 0) % 60}s bacha hua hai
              </div>
            </div>
          </div>
        )}

        {error && <div style={{ color:'#DC2626', marginBottom:16, textAlign:'center', fontSize:13 }}>⚠️ {error}</div>}

        {/* Action buttons */}
        <div style={{ display:'flex', gap:12 }}>
          <button onClick={() => router.back()}
            style={{ flex:1, padding:'14px', borderRadius:10, border:'1px solid #E2E8F0', background:'white', cursor:'pointer', fontWeight:600, fontSize:14, color:'#475569' }}>
            ← Back to Exam
          </button>
          <button onClick={() => handleSubmit(false)} disabled={submitting}
            style={{ flex:2, padding:'14px', borderRadius:10, border:'none', background: submitting ? '#94A3B8' : '#EF4444', color:'white', cursor: submitting ? 'not-allowed' : 'pointer', fontWeight:700, fontSize:15, boxShadow:'0 4px 12px rgba(239,68,68,0.3)' }}>
            {submitting ? '⟳ Submitting...' : '✅ Final Submit'}
          </button>
        </div>

        <div style={{ marginTop:16, textAlign:'center', fontSize:12, color:'#94A3B8' }}>
          Submit karne ke baad changes nahi ho sakte. Result abhi calculate hoga.
        </div>
      </div>
    </div>
  );
}
