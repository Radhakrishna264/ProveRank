'use client';
import { useEffect, useState } from 'react';
import { getToken } from '@/lib/auth';
import Link from 'next/link';

/* ── Countdown Hook ── */
function useCountdown(d: string) {
  const [t, setT] = useState({ d:0, h:0, m:0, s:0, u:false });
  useEffect(() => {
    const calc = () => {
      const diff = new Date(d).getTime() - Date.now();
      if (diff <= 0) { setT({ d:0, h:0, m:0, s:0, u:false }); return; }
      setT({ d:Math.floor(diff/86400000), h:Math.floor((diff%86400000)/3600000), m:Math.floor((diff%3600000)/60000), s:Math.floor((diff%60000)/1000), u:diff<86400000 });
    };
    calc();
    const id = setInterval(calc, 1000);
    return () => clearInterval(id);
  }, [d]);
  return t;
}

/* ── S100: Onboarding Tour ── */
function Tour({ onDone }: { onDone: () => void }) {
  const steps = [
    { title:'Apna Dashboard 📊',  body:'Yahan apna rank, score, aur upcoming exams dekho ek hi jagah!' },
    { title:'Exams Join Karo 📝', body:'Available Exams section mein apne batch ke saare exams milenge.' },
    { title:'Badges Earn Karo 🏆',body:'Exams do aur Trophy Room mein badges unlock karo!' },
    { title:'Goal Set Karo 🎯',   body:'Apna target NEET rank set karo — dashboard track karega.' },
  ];
  const [i, setI] = useState(0);
  return (
    <div style={{ position:'fixed', inset:0, zIndex:9999, background:'rgba(0,10,24,0.88)', display:'flex', alignItems:'center', justifyContent:'center' }}>
      <div style={{ background:'var(--card)', border:'1px solid var(--primary)', borderRadius:16, padding:32, maxWidth:400, width:'90%', textAlign:'center', animation:'fadeIn 0.3s ease' }}>
        <div style={{ fontSize:40, marginBottom:8 }}>⬡</div>
        <div style={{ color:'var(--muted)', fontSize:12, marginBottom:6 }}>Step {i+1} of {steps.length}</div>
        <h2 style={{ fontFamily:'Playfair Display,serif', fontSize:22, color:'var(--primary)', marginBottom:12 }}>{steps[i].title}</h2>
        <p style={{ color:'var(--text)', fontSize:14, lineHeight:1.7, marginBottom:24 }}>{steps[i].body}</p>
        <div style={{ display:'flex', gap:12, justifyContent:'center' }}>
          <button onClick={onDone} style={{ background:'none', border:'1px solid var(--border)', color:'var(--muted)', borderRadius:8, padding:'8px 20px', cursor:'pointer', fontSize:13 }}>Skip</button>
          <button onClick={() => i < steps.length-1 ? setI(i+1) : onDone()} style={{ background:'var(--primary)', color:'#000A18', border:'none', borderRadius:8, padding:'8px 24px', cursor:'pointer', fontWeight:700, fontSize:13 }}>
            {i === steps.length-1 ? '🚀 Start!' : 'Next →'}
          </button>
        </div>
        <div style={{ display:'flex', gap:6, justifyContent:'center', marginTop:16 }}>
          {steps.map((_, x) => <div key={x} style={{ width:8, height:8, borderRadius:4, background:x===i?'var(--primary)':'var(--border)', transition:'background 0.3s' }}/>)}
        </div>
      </div>
    </div>
  );
}

/* ── N3: Onboarding Checklist ── */
function Checklist({ exams }: { exams: number }) {
  const tasks = [
    { label:'Profile complete karo', done:true,      icon:'👤' },
    { label:'Pehla exam do',         done:exams > 0, icon:'📝' },
    { label:'Result dekho',          done:exams > 0, icon:'📊' },
    { label:'Goal set karo',         done:false,     icon:'🎯' },
  ];
  const n = tasks.filter(t => t.done).length;
  return (
    <div style={{ background:'var(--card)', border:'1px solid var(--border)', borderRadius:14, padding:20 }}>
      <div style={{ display:'flex', justifyContent:'space-between', marginBottom:12 }}>
        <span style={{ fontFamily:'Playfair Display,serif', fontSize:15, color:'var(--text)' }}>🎮 Getting Started</span>
        <span style={{ fontSize:12, color:'var(--primary)', fontWeight:600 }}>{n}/{tasks.length}</span>
      </div>
      <div style={{ background:'var(--border)', borderRadius:4, height:6, marginBottom:14, overflow:'hidden' }}>
        <div style={{ width:`${(n/tasks.length)*100}%`, height:'100%', background:'linear-gradient(90deg,#4D9FFF,#00C9FF)', borderRadius:4, transition:'width 1s ease' }}/>
      </div>
      {tasks.map(t => (
        <div key={t.label} style={{ display:'flex', alignItems:'center', gap:10, padding:'7px 10px', borderRadius:8, background:t.done?'rgba(77,159,255,0.07)':'transparent', marginBottom:4 }}>
          <span>{t.done ? '✅' : '⬜'}</span>
          <span style={{ fontSize:13, color:t.done?'var(--text)':'var(--muted)' }}>{t.icon} {t.label}</span>
        </div>
      ))}
    </div>
  );
}

/* ── N1: Goal Setting ── */
function GoalBox({ rank }: { rank: number }) {
  const [edit,   setEdit]   = useState(false);
  const [target, setTarget] = useState(100);
  const [saving, setSaving] = useState(false);

  const save = async () => {
    setSaving(true);
    try {
      await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/students/goal`, {
        method:'POST', headers:{ 'Content-Type':'application/json', Authorization:`Bearer ${getToken()}` },
        body: JSON.stringify({ targetRank: target }),
      });
    } catch {}
    setSaving(false); setEdit(false);
  };

  const pct = rank && target ? Math.max(0, Math.min(100, rank <= target ? 100 : ((target/rank)*80))) : 0;

  return (
    <div style={{ background:'var(--card)', border:'1px solid var(--border)', borderRadius:14, padding:20 }}>
      <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:12 }}>
        <span style={{ fontFamily:'Playfair Display,serif', fontSize:15, color:'var(--text)' }}>🎯 My Goal</span>
        <button onClick={() => setEdit(!edit)} style={{ background:'none', border:'1px solid var(--border)', color:'var(--muted)', borderRadius:6, padding:'3px 9px', cursor:'pointer', fontSize:11 }}>
          {edit ? 'Cancel' : '✏️ Edit'}
        </button>
      </div>
      {edit ? (
        <div style={{ display:'flex', gap:8, alignItems:'center' }}>
          <span style={{ fontSize:12, color:'var(--muted)' }}>Target:</span>
          <input type="number" value={target} min={1} max={9999} onChange={e => setTarget(Number(e.target.value))}
            style={{ background:'var(--bg)', border:'1px solid var(--border)', borderRadius:6, color:'var(--text)', padding:'6px 10px', width:80, fontSize:14 }}/>
          <button onClick={save} disabled={saving} style={{ background:'var(--primary)', color:'#000A18', border:'none', borderRadius:6, padding:'6px 14px', cursor:'pointer', fontWeight:600, fontSize:13 }}>
            {saving ? '...' : 'Save'}
          </button>
        </div>
      ) : (
        <>
          <div style={{ display:'flex', justifyContent:'space-between', fontSize:13, marginBottom:8 }}>
            <span style={{ color:'var(--muted)' }}>Current Rank</span>
            <span style={{ color:'#4D9FFF', fontWeight:700 }}>#{rank || '—'}</span>
          </div>
          <div style={{ display:'flex', justifyContent:'space-between', fontSize:13, marginBottom:12 }}>
            <span style={{ color:'var(--muted)' }}>Target Rank</span>
            <span style={{ color:'#FFD700', fontWeight:700 }}>#{target}</span>
          </div>
          <div style={{ background:'rgba(0,0,0,0.3)', borderRadius:6, height:8, overflow:'hidden', marginBottom:4 }}>
            <div style={{ width:`${pct}%`, height:'100%', background:'linear-gradient(90deg,#4D9FFF,#00C9FF)', borderRadius:6, transition:'width 1s' }}/>
          </div>
          <div style={{ fontSize:11, color:'var(--muted)', textAlign:'right' }}>{Math.round(pct)}% complete</div>
        </>
      )}
    </div>
  );
}

/* ── N4: Performance vs NEET Cutoff ── */
function NEETBar({ score }: { score: number }) {
  const bars = [
    { label:'Your Score',    v:score, color:'#4D9FFF' },
    { label:'General Cutoff',v:360,   color:'#FFD700' },
    { label:'OBC Cutoff',    v:288,   color:'#FF8C00' },
  ];
  return (
    <div style={{ background:'var(--card)', border:'1px solid var(--border)', borderRadius:14, padding:20 }}>
      <div style={{ fontFamily:'Playfair Display,serif', fontSize:15, color:'var(--text)', marginBottom:4 }}>📊 vs NEET Cutoff</div>
      <div style={{ fontSize:12, color:'var(--muted)', marginBottom:14 }}>Kitne marks aur chahiye</div>
      {bars.map(b => {
        const pct = Math.min((b.v / 720) * 100, 100);
        const gap = b.label === 'Your Score' ? Math.max(0, 360 - b.v) : null;
        return (
          <div key={b.label} style={{ marginBottom:14 }}>
            <div style={{ display:'flex', justifyContent:'space-between', fontSize:12, marginBottom:5 }}>
              <span style={{ color:'var(--muted)' }}>{b.label}</span>
              <span style={{ color:b.color, fontWeight:600 }}>{b.v}/720</span>
            </div>
            <div style={{ background:'rgba(0,0,0,0.3)', borderRadius:6, height:10, overflow:'hidden' }}>
              <div style={{ width:`${pct}%`, height:'100%', background:`linear-gradient(90deg,${b.color}88,${b.color})`, borderRadius:6, transition:'width 1.2s' }}/>
            </div>
            {gap !== null && gap > 0  && <div style={{ fontSize:11, color:'#FF7777', marginTop:3 }}>⬆️ {gap} marks aur chahiye</div>}
            {gap !== null && gap <= 0 && <div style={{ fontSize:11, color:'#4DFF90', marginTop:3 }}>✅ Cutoff se upar ho!</div>}
          </div>
        );
      })}
    </div>
  );
}

/* ── C1: Countdown Card ── */
function CountdownCard({ exam }: { exam: any }) {
  const { d, h, m, s, u } = useCountdown(exam.scheduledFor);
  const col = u ? '#FF4D4D' : '#4D9FFF';
  return (
    <div style={{ background:'var(--card)', border:`1px solid ${u?'rgba(255,77,77,0.4)':'var(--border)'}`, borderRadius:14, padding:16, marginBottom:12 }}>
      <div style={{ fontSize:12, color:'var(--muted)', marginBottom:4 }}>{exam.seriesName || 'Upcoming'}</div>
      <div style={{ fontSize:14, fontWeight:600, color:'var(--text)', marginBottom:12, lineHeight:1.3 }}>{exam.title}</div>
      <div style={{ display:'flex', gap:8, justifyContent:'center', marginBottom:8 }}>
        {[{v:d,l:'D'},{v:h,l:'H'},{v:m,l:'M'},{v:s,l:'S'}].map(({ v, l }) => (
          <div key={l} style={{ textAlign:'center', background:`${col}18`, border:`1px solid ${col}33`, borderRadius:8, padding:'6px 10px', minWidth:44 }}>
            <div style={{ fontSize:20, fontWeight:700, color:col, fontVariantNumeric:'tabular-nums' }}>{String(v).padStart(2,'0')}</div>
            <div style={{ fontSize:9, color:'var(--muted)' }}>{l}</div>
          </div>
        ))}
      </div>
      {u && <div style={{ textAlign:'center', fontSize:11, color:'#FF4D4D', fontWeight:600 }}>⚠️ 24 hrs se kam!</div>}
      <Link href={`/dashboard/exams/${exam._id}/countdown`}>
        <button style={{ width:'100%', marginTop:10, background:col, color:u?'#fff':'#000A18', border:'none', borderRadius:8, padding:8, cursor:'pointer', fontWeight:600, fontSize:13 }}>
          View →
        </button>
      </Link>
    </div>
  );
}

/* ── S42: Badges Mini (B3 Trophy Room) ── */
function BadgesMini({ list }: { list: any[] }) {
  const def = [
    { id:'first',  name:'First Attempt', icon:'🥇', earned:false },
    { id:'streak', name:'7 Day Streak',  icon:'🔥', earned:false },
    { id:'perfect',name:'Perfect Score', icon:'💯', earned:false },
    { id:'top10',  name:'Top 10',        icon:'🏆', earned:false },
    { id:'bio',    name:'Bio Master',    icon:'🧬', earned:false },
    { id:'neet',   name:'NEET Ready',    icon:'🎯', earned:false },
  ];
  const show = list.length ? list : def;
  return (
    <div style={{ background:'var(--card)', border:'1px solid var(--border)', borderRadius:14, padding:20 }}>
      <div style={{ display:'flex', justifyContent:'space-between', marginBottom:14 }}>
        <span style={{ fontFamily:'Playfair Display,serif', fontSize:15, color:'var(--text)' }}>🏅 Trophy Room</span>
        <Link href="/dashboard/badges"><span style={{ fontSize:12, color:'var(--primary)' }}>All →</span></Link>
      </div>
      <div style={{ display:'grid', gridTemplateColumns:'repeat(3,1fr)', gap:10 }}>
        {show.slice(0,6).map(b => (
          <div key={b.id} style={{ textAlign:'center', padding:12, borderRadius:10, background:b.earned?'rgba(77,159,255,0.12)':'rgba(0,0,0,0.2)', border:b.earned?'1px solid rgba(77,159,255,0.4)':'1px solid var(--border)', filter:b.earned?'none':'grayscale(1) opacity(0.4)', transition:'transform 0.2s' }}
            onMouseEnter={e => b.earned && ((e.currentTarget as HTMLDivElement).style.transform='scale(1.08)')}
            onMouseLeave={e =>             ((e.currentTarget as HTMLDivElement).style.transform='scale(1)')}>
            <div style={{ fontSize:26 }}>{b.earned ? b.icon : '🔒'}</div>
            <div style={{ fontSize:10, color:'var(--muted)', marginTop:4 }}>{b.name}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

/* ── S12: Notices Mini ── */
function NoticesMini({ list }: { list: any[] }) {
  return (
    <div style={{ background:'var(--card)', border:'1px solid var(--border)', borderRadius:14, padding:20 }}>
      <div style={{ display:'flex', justifyContent:'space-between', marginBottom:14 }}>
        <span style={{ fontFamily:'Playfair Display,serif', fontSize:15, color:'var(--text)' }}>📋 Notice Board</span>
        <Link href="/dashboard/notices"><span style={{ fontSize:12, color:'var(--primary)' }}>All →</span></Link>
      </div>
      {list.length === 0
        ? <div style={{ color:'var(--muted)', fontSize:13, textAlign:'center', padding:16 }}>Koi notice nahi</div>
        : list.slice(0,3).map(n => (
          <div key={n._id} style={{ padding:'10px 12px', borderRadius:8, background:'rgba(77,159,255,0.06)', borderLeft:'3px solid var(--primary)', marginBottom:8 }}>
            <div style={{ fontSize:13, fontWeight:600, color:'var(--text)', marginBottom:4 }}>{n.title}</div>
            <div style={{ fontSize:12, color:'var(--muted)', lineHeight:1.5 }}>{(n.message||'').slice(0,80)}{(n.message||'').length>80?'...':''}</div>
          </div>
        ))
      }
    </div>
  );
}

/* ── MAIN DASHBOARD PAGE ── */
export default function DashboardPage() {
  const [data,    setData]    = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [tour,    setTour]    = useState(false);

  useEffect(() => {
    if (!localStorage.getItem('pr_tour_done')) setTour(true);
    const token = getToken();
    Promise.allSettled([
      fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/auth/me`,                     { headers:{ Authorization:`Bearer ${token}` } }),
      fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/exams?status=upcoming&limit=3`,{ headers:{ Authorization:`Bearer ${token}` } }),
      fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/admin/notices?limit=5`,        { headers:{ Authorization:`Bearer ${token}` } }),
    ]).then(async ([me, ex, no]) => {
      const m = me.status==='fulfilled' ? await (me.value as Response).json() : {};
      const e = ex.status==='fulfilled' ? await (ex.value as Response).json() : [];
      const n = no.status==='fulfilled' ? await (no.value as Response).json() : [];
      setData({
        student: { name:m.name||'Student', rank:m.rank||0, score:m.bestScore||0, percentile:m.percentile||0, streak:m.streak||0, totalExams:m.totalExams||0, accuracy:m.accuracy||0 },
        exams:   Array.isArray(e) ? e : e.exams   || [],
        notices: Array.isArray(n) ? n : n.notices || [],
        badges:  m.badges || [],
      });
      setLoading(false);
    });
  }, []);

  if (loading) return (
    <div style={{ display:'flex', alignItems:'center', justifyContent:'center', height:'60vh', flexDirection:'column', gap:16 }}>
      <div style={{ width:44, height:44, border:'3px solid var(--border)', borderTop:'3px solid var(--primary)', borderRadius:'50%', animation:'spin 0.8s linear infinite' }}/>
      <div style={{ color:'var(--muted)', fontSize:14 }}>Loading dashboard...</div>
    </div>
  );

  const { student, exams, notices, badges } = data;

  return (
    <div>
      {tour && <Tour onDone={() => { localStorage.setItem('pr_tour_done','1'); setTour(false); }}/>}

      {/* Welcome Banner */}
      <div style={{ background:'linear-gradient(135deg,#001628,#002D55)', border:'1px solid var(--border)', borderRadius:16, padding:'20px 24px', marginBottom:24, display:'flex', alignItems:'center', justifyContent:'space-between' }}>
        <div>
          <div style={{ fontFamily:'Playfair Display,serif', fontSize:22, color:'var(--accent)', fontWeight:700 }}>
            Namaste, {student.name} 👋
          </div>
          <div style={{ color:'var(--muted)', fontSize:13, marginTop:4 }}>
            🔥 {student.streak} day streak · 🏆 Rank #{student.rank||'—'} · 📝 {student.totalExams} exams
          </div>
        </div>
        <button onClick={() => { localStorage.removeItem('pr_tour_done'); setTour(true); }}
          style={{ background:'rgba(77,159,255,0.1)', border:'1px solid rgba(77,159,255,0.3)', color:'var(--primary)', borderRadius:8, padding:'8px 14px', cursor:'pointer', fontSize:12 }}>
          🗺️ Tour
        </button>
      </div>

      {/* S41 Stat Cards */}
      <div style={{ display:'grid', gridTemplateColumns:'repeat(4,1fr)', gap:16, marginBottom:24 }}>
        {[
          { label:'Best Score',  value:`${student.score}/720`,                    color:'#4D9FFF', icon:'📊' },
          { label:'Rank',        value:student.rank?`#${student.rank}`:'—',       color:'#FFD700', icon:'🏆' },
          { label:'Percentile',  value:`${Number(student.percentile).toFixed(1)}%`,color:'#4DFF90', icon:'📈' },
          { label:'Accuracy',    value:`${Number(student.accuracy).toFixed(0)}%`, color:'#FF9F4D', icon:'🎯' },
        ].map(s => (
          <div key={s.label} style={{ background:'var(--card)', border:'1px solid var(--border)', borderRadius:14, padding:'18px 16px', textAlign:'center' }}>
            <div style={{ fontSize:22, marginBottom:6 }}>{s.icon}</div>
            <div style={{ fontSize:24, fontWeight:700, color:s.color }}>{s.value}</div>
            <div style={{ fontSize:12, color:'var(--muted)', marginTop:4 }}>{s.label}</div>
          </div>
        ))}
      </div>

      {/* 3-Column Grid */}
      <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr 1fr', gap:20, marginBottom:20 }}>
        <div style={{ display:'flex', flexDirection:'column', gap:20 }}>
          <Checklist exams={student.totalExams}/>
          <GoalBox rank={student.rank}/>
        </div>
        <div style={{ display:'flex', flexDirection:'column', gap:20 }}>
          <NEETBar score={student.score}/>
        </div>
        <div style={{ background:'var(--card)', border:'1px solid var(--border)', borderRadius:14, padding:20 }}>
          <div style={{ display:'flex', justifyContent:'space-between', marginBottom:14 }}>
            <span style={{ fontFamily:'Playfair Display,serif', fontSize:15, color:'var(--text)' }}>⏰ Upcoming Exams</span>
            <Link href="/dashboard/exams"><span style={{ fontSize:12, color:'var(--primary)' }}>All →</span></Link>
          </div>
          {exams.length === 0
            ? <div style={{ color:'var(--muted)', fontSize:13, textAlign:'center', padding:16 }}>No upcoming exams</div>
            : exams.slice(0,2).map((e: any) => <CountdownCard key={e._id} exam={e}/>)
          }
        </div>
      </div>

      {/* Row 2 */}
      <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:20 }}>
        <BadgesMini list={badges}/>
        <NoticesMini list={notices}/>
      </div>
    </div>
  );
}
