'use client';
import { useEffect, useState } from 'react';
import { getToken } from '@/lib/auth';
import Link from 'next/link';

export default function ExamsPage() {
  const [exams,   setExams]   = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter,  setFilter]  = useState<'all'|'upcoming'|'active'|'completed'>('all');
  const [search,  setSearch]  = useState('');

  useEffect(() => {
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/exams`, { headers:{ Authorization:`Bearer ${getToken()}` } })
      .then(r => r.json())
      .then(d => { setExams(Array.isArray(d) ? d : d.exams || []); setLoading(false); })
      .catch(() => setLoading(false));
  }, []);

  const STATUS: Record<string,{color:string;bg:string;label:string}> = {
    upcoming:  { color:'#FFD700', bg:'rgba(255,215,0,0.1)',   label:'⏳ Upcoming' },
    active:    { color:'#4DFF90', bg:'rgba(77,255,144,0.1)',  label:'🔴 LIVE'     },
    completed: { color:'#6B8FAF', bg:'rgba(107,143,175,0.1)',label:'✅ Done'      },
  };

  const filtered = exams.filter(e => {
    const fMatch = filter === 'all' || e.status === filter;
    const sMatch = !search || e.title.toLowerCase().includes(search.toLowerCase()) || (e.seriesName||'').toLowerCase().includes(search.toLowerCase());
    return fMatch && sMatch;
  });

  return (
    <div>
      <div style={{ fontFamily:'Playfair Display,serif', fontSize:22, color:'var(--text)', marginBottom:4 }}>📝 Available Exams</div>
      <div style={{ color:'var(--muted)', fontSize:13, marginBottom:20 }}>Apne batch ke saare exams yahan milenge</div>

      <div style={{ display:'flex', gap:12, marginBottom:20, flexWrap:'wrap', alignItems:'center' }}>
        <input value={search} onChange={e => setSearch(e.target.value)} placeholder="🔍 Search exam..."
          style={{ background:'var(--card)', border:'1px solid var(--border)', borderRadius:8, padding:'8px 14px', color:'var(--text)', fontSize:13, minWidth:200, outline:'none' }}/>
        <div style={{ display:'flex', gap:8 }}>
          {(['all','upcoming','active','completed'] as const).map(f => (
            <button key={f} onClick={() => setFilter(f)} style={{ background:filter===f?'var(--primary)':'var(--card)', color:filter===f?'#000A18':'var(--muted)', border:'1px solid var(--border)', borderRadius:8, padding:'6px 14px', cursor:'pointer', fontSize:12, fontWeight:600 }}>
              {f.charAt(0).toUpperCase()+f.slice(1)}
            </button>
          ))}
        </div>
      </div>

      {loading ? <div style={{ textAlign:'center', color:'var(--muted)', padding:40 }}>Loading...</div>
       : filtered.length === 0
        ? <div style={{ textAlign:'center', color:'var(--muted)', padding:60, background:'var(--card)', borderRadius:14, border:'1px solid var(--border)' }}>
            <div style={{ fontSize:40, marginBottom:12 }}>📭</div>
            <div>Koi exam nahi mila</div>
          </div>
        : <div style={{ display:'grid', gridTemplateColumns:'repeat(auto-fill,minmax(320px,1fr))', gap:16 }}>
            {filtered.map(exam => {
              const cfg = STATUS[exam.status] || STATUS.upcoming;
              const isLive = exam.status === 'active';
              return (
                <div key={exam._id} style={{ background:'var(--card)', border:`1px solid ${isLive?'rgba(77,255,144,0.4)':'var(--border)'}`, borderRadius:14, padding:20, display:'flex', flexDirection:'column', gap:12, boxShadow:isLive?'0 0 20px rgba(77,255,144,0.08)':'none' }}>
                  <div style={{ display:'flex', justifyContent:'space-between', alignItems:'flex-start' }}>
                    <div style={{ flex:1, marginRight:8 }}>
                      {exam.seriesName && <div style={{ fontSize:11, color:'var(--primary)', marginBottom:4 }}>{exam.seriesName}</div>}
                      <div style={{ fontSize:15, fontWeight:600, color:'var(--text)', lineHeight:1.3 }}>{exam.title}</div>
                    </div>
                    <span style={{ fontSize:11, color:cfg.color, background:cfg.bg, border:`1px solid ${cfg.color}44`, borderRadius:20, padding:'2px 10px', fontWeight:600, whiteSpace:'nowrap' }}>{cfg.label}</span>
                  </div>
                  <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:8 }}>
                    {[['📅','Date',new Date(exam.scheduledFor).toLocaleDateString('en-IN')],['⏱️','Duration',`${exam.duration} min`],['📊','Marks',`${exam.totalMarks}`],['❓','Questions',`${exam.totalQuestions}`]].map(([ic,lb,vl])=>(
                      <div key={lb} style={{ background:'var(--bg)', borderRadius:8, padding:'6px 10px' }}>
                        <div style={{ fontSize:10, color:'var(--muted)' }}>{ic} {lb}</div>
                        <div style={{ fontSize:13, color:'var(--text)', fontWeight:600 }}>{vl}</div>
                      </div>
                    ))}
                  </div>
                  <div style={{ display:'flex', gap:8 }}>
                    {isLive && !exam.hasAttempted && (
                      <Link href={`/exam/${exam._id}/attempt`} style={{ flex:1 }}>
                        <button style={{ width:'100%', background:'#4DFF90', color:'#000A18', border:'none', borderRadius:8, padding:10, cursor:'pointer', fontWeight:700, fontSize:14 }}>🚀 Attempt Now</button>
                      </Link>
                    )}
                    {exam.status === 'upcoming' && (
                      <Link href={`/dashboard/exams/${exam._id}/countdown`} style={{ flex:1 }}>
                        <button style={{ width:'100%', background:'rgba(77,159,255,0.12)', color:'var(--primary)', border:'1px solid rgba(77,159,255,0.3)', borderRadius:8, padding:10, cursor:'pointer', fontWeight:600, fontSize:13 }}>⏰ Countdown</button>
                      </Link>
                    )}
                    {exam.status === 'completed' && (
                      <Link href={`/dashboard/results?exam=${exam._id}`} style={{ flex:1 }}>
                        <button style={{ width:'100%', background:'rgba(107,143,175,0.1)', color:'var(--muted)', border:'1px solid var(--border)', borderRadius:8, padding:10, cursor:'pointer', fontWeight:600, fontSize:13 }}>📊 Result</button>
                      </Link>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
      }
    </div>
  );
}
