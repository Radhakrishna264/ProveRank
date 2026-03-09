#!/bin/bash
# ============================================================
# ProveRank Phase 7.2 — Student Dashboard & Profile
# ALL 13 STEPS — SINGLE COMPLETE SCRIPT
# Rule C1: cat > EOF style | Rule A1: Android paste friendly
# Design: PR4 Hex + N6 Neon Blue Arctic + F1 Playfair+Inter
# Layout: D1 Sidebar Dashboard
# Steps: S100 N3 S41 S42 N1 N4 S12 S5 S96 S106 S10 S7 S21
# ============================================================

cd ~/workspace/frontend

# ── DIRECTORIES ──
mkdir -p src/app/dashboard
mkdir -p src/app/dashboard/profile
mkdir -p src/app/dashboard/exams
mkdir -p "src/app/dashboard/exams/[examId]/countdown"
mkdir -p src/app/dashboard/notifications
mkdir -p src/app/dashboard/notices
mkdir -p src/app/dashboard/badges
mkdir -p src/app/dashboard/admit-card
mkdir -p src/app/dashboard/certificates

echo "📁 Directories created"

# ════════════════════════════════════════════════════════════
# FILE 1 — Dashboard Layout (D1 Sidebar + DL1 Theme Toggle)
# ════════════════════════════════════════════════════════════
cat > src/app/dashboard/layout.tsx << 'ENDOFFILE'
'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { getToken, getRole, logout } from '@/lib/auth';

const NAV = [
  { href: '/dashboard',                  label: 'Dashboard',    icon: '📊', exact: true },
  { href: '/dashboard/profile',          label: 'Profile',      icon: '👤' },
  { href: '/dashboard/exams',            label: 'Exams',        icon: '📝' },
  { href: '/dashboard/badges',           label: 'Achievements', icon: '🏆' },
  { href: '/dashboard/notices',          label: 'Notices',      icon: '📋' },
  { href: '/dashboard/notifications',    label: 'Notifications',icon: '🔔' },
  { href: '/dashboard/certificates',     label: 'Certificates', icon: '🎓' },
  { href: '/dashboard/admit-card',       label: 'Admit Card',   icon: '🎫' },
];

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router   = useRouter();
  const [theme, setTheme]   = useState('dark');
  const [user,  setUser]    = useState<{ name?: string; email?: string } | null>(null);
  const [unread, setUnread] = useState(0);

  useEffect(() => {
    const token = getToken();
    const role  = getRole();
    if (!token || role !== 'student') { router.push('/login'); return; }

    const t = localStorage.getItem('pr_theme') || 'dark';
    setTheme(t);
    document.documentElement.setAttribute('data-theme', t);

    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/auth/me`, {
      headers: { Authorization: `Bearer ${token}` },
    }).then(r => r.json()).then(d => setUser(d)).catch(() => {});

    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/notifications?unread=true`, {
      headers: { Authorization: `Bearer ${token}` },
    }).then(r => r.json()).then(d => setUnread(d.count || 0)).catch(() => {});
  }, [router]);

  const toggleTheme = () => {
    const next = theme === 'dark' ? 'light' : 'dark';
    setTheme(next);
    localStorage.setItem('pr_theme', next);
    document.documentElement.setAttribute('data-theme', next);
  };

  const isActive = (item: { href: string; exact?: boolean }) =>
    item.exact ? pathname === item.href : pathname.startsWith(item.href);

  return (
    <div style={{ display:'flex', minHeight:'100vh', background:'var(--bg)', color:'var(--text)', fontFamily:'Inter,sans-serif' }}>
      <style>{`
        :root { --bg:#000A18; --card:#001628; --primary:#4D9FFF; --accent:#FFFFFF; --border:#002D55; --text:#E8F4FF; --muted:#6B8FAF; }
        [data-theme="light"] { --bg:#f0f4ff; --card:#ffffff; --primary:#1a6fd4; --accent:#000A18; --border:#c5d8f0; --text:#0a1628; --muted:#4a6080; }
        * { box-sizing:border-box; margin:0; padding:0; }
        a { text-decoration:none; color:inherit; }
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600&display=swap');
        ::-webkit-scrollbar { width:4px; }
        ::-webkit-scrollbar-track { background:var(--card); }
        ::-webkit-scrollbar-thumb { background:var(--border); border-radius:2px; }
        .snav { display:flex; align-items:center; gap:10px; padding:10px 16px; border-radius:10px; transition:all 0.2s; font-size:14px; font-weight:500; cursor:pointer; }
        .snav:hover { background:rgba(77,159,255,0.12); color:var(--primary); }
        .snav.on  { background:rgba(77,159,255,0.18); color:var(--primary); border-left:3px solid var(--primary); }
        @keyframes spin { to { transform:rotate(360deg); } }
        @keyframes slideIn { from { transform:translateX(100%); } to { transform:translateX(0); } }
        @keyframes pulse { 0%,100% { opacity:1; } 50% { opacity:0.6; } }
        @keyframes fadeIn { from { opacity:0; transform:translateY(8px); } to { opacity:1; transform:translateY(0); } }
      `}</style>

      {/* ── SIDEBAR ── */}
      <aside style={{
        width:230, minWidth:230, background:'var(--card)', borderRight:'1px solid var(--border)',
        display:'flex', flexDirection:'column', padding:'20px 12px',
        position:'sticky', top:0, height:'100vh', overflowY:'auto', zIndex:100,
      }}>
        {/* PR4 Logo */}
        <div style={{ display:'flex', alignItems:'center', gap:10, padding:'0 8px 24px', borderBottom:'1px solid var(--border)' }}>
          <div style={{ fontSize:28, color:'var(--primary)', lineHeight:1 }}>⬡</div>
          <span style={{ fontFamily:'Playfair Display,Georgia,serif', fontSize:18, color:'var(--primary)', fontWeight:700 }}>ProveRank</span>
        </div>

        {/* Nav Links */}
        <nav style={{ marginTop:16, display:'flex', flexDirection:'column', gap:4, flex:1 }}>
          {NAV.map(item => (
            <Link key={item.href} href={item.href} className={`snav${isActive(item) ? ' on' : ''}`}>
              <span style={{ fontSize:16 }}>{item.icon}</span>
              <span>{item.label}</span>
              {item.href === '/dashboard/notifications' && unread > 0 && (
                <span style={{ marginLeft:'auto', background:'#FF4D4D', color:'white', borderRadius:20, padding:'1px 7px', fontSize:10, fontWeight:700 }}>
                  {unread}
                </span>
              )}
            </Link>
          ))}
        </nav>

        {/* User + Logout */}
        <div style={{ borderTop:'1px solid var(--border)', paddingTop:16, display:'flex', flexDirection:'column', gap:8 }}>
          {user && (
            <div style={{ padding:8, borderRadius:8, background:'rgba(77,159,255,0.06)' }}>
              <div style={{ fontSize:13, fontWeight:600, color:'var(--text)' }}>{user.name || 'Student'}</div>
              <div style={{ fontSize:11, color:'var(--muted)' }}>{user.email || ''}</div>
            </div>
          )}
          <button
            onClick={() => { logout(); router.push('/login'); }}
            style={{ background:'rgba(255,77,77,0.1)', border:'1px solid rgba(255,77,77,0.3)', color:'#FF7777', borderRadius:8, padding:8, cursor:'pointer', fontSize:13, fontWeight:500 }}>
            🚪 Logout
          </button>
        </div>
      </aside>

      {/* ── MAIN CONTENT ── */}
      <div style={{ flex:1, display:'flex', flexDirection:'column', overflow:'auto' }}>
        {/* Top Bar */}
        <header style={{
          background:'var(--card)', borderBottom:'1px solid var(--border)',
          padding:'12px 24px', display:'flex', alignItems:'center', justifyContent:'space-between',
          position:'sticky', top:0, zIndex:50,
        }}>
          <div style={{ fontFamily:'Playfair Display,serif', fontSize:16, color:'var(--text)', fontWeight:700 }}>
            {NAV.find(n => isActive(n))?.label || 'Dashboard'}
          </div>
          <div style={{ display:'flex', alignItems:'center', gap:16 }}>
            {/* DL1 Dark/Light Toggle */}
            <button onClick={toggleTheme} style={{ background:'none', border:'1px solid var(--border)', borderRadius:20, padding:'4px 12px', cursor:'pointer', color:'var(--muted)', fontSize:13 }}>
              {theme === 'dark' ? '☀️ Light' : '🌙 Dark'}
            </button>
            {/* S10 Notification Bell */}
            <Link href="/dashboard/notifications" style={{ position:'relative', fontSize:20, color:'var(--muted)' }}>
              🔔
              {unread > 0 && (
                <span style={{ position:'absolute', top:-4, right:-4, background:'#FF4D4D', color:'white', borderRadius:'50%', width:16, height:16, fontSize:10, display:'flex', alignItems:'center', justifyContent:'center', fontWeight:700 }}>
                  {unread}
                </span>
              )}
            </Link>
          </div>
        </header>

        {/* Page Content */}
        <main style={{ flex:1, padding:24 }}>{children}</main>
      </div>
    </div>
  );
}
ENDOFFILE
echo "✅ 1/13 — Layout (D1 Sidebar + DL1 Theme Toggle)"

# ════════════════════════════════════════════════════════════
# FILE 2 — Main Dashboard Page
# S100 Tour + N3 Checklist + S41 Widgets + S42 Badges
# N1 Goal + N4 NEET Cutoff + S12 Notices + C1 Countdown
# ════════════════════════════════════════════════════════════
cat > src/app/dashboard/page.tsx << 'ENDOFFILE'
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
ENDOFFILE
echo "✅ 2/13 — Dashboard (S41+S100+N3+S42+N1+N4+S12+C1)"

# ════════════════════════════════════════════════════════════
# FILE 3 — Student Profile Page (S7 + P2 Cover Photo Style)
# ════════════════════════════════════════════════════════════
cat > src/app/dashboard/profile/page.tsx << 'ENDOFFILE'
'use client';
import { useEffect, useRef, useState } from 'react';
import { getToken } from '@/lib/auth';
import Link from 'next/link';

export default function ProfilePage() {
  const [p,       setP]       = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const photoRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/auth/me`, { headers:{ Authorization:`Bearer ${getToken()}` } })
      .then(r => r.json()).then(d => { setP(d); setLoading(false); }).catch(() => setLoading(false));
  }, []);

  if (loading) return (
    <div style={{ display:'flex', justifyContent:'center', alignItems:'center', height:'60vh' }}>
      <div style={{ width:40, height:40, border:'3px solid var(--border)', borderTop:'3px solid var(--primary)', borderRadius:'50%', animation:'spin 0.8s linear infinite' }}/>
    </div>
  );
  if (!p) return <div style={{ color:'var(--muted)', textAlign:'center', marginTop:60 }}>Profile load nahi hua.</div>;

  const stats = [
    { label:'Best Score', value:`${p.bestScore||0}/720`,                              color:'#4D9FFF' },
    { label:'Rank',       value:p.rank?`#${p.rank}`:'—',                              color:'#FFD700' },
    { label:'Percentile', value:p.percentile?`${Number(p.percentile).toFixed(1)}%`:'—',color:'#4DFF90' },
    { label:'Exams',      value:p.totalExams||0,                                       color:'#FF9F4D' },
    { label:'Accuracy',   value:p.accuracy?`${Number(p.accuracy).toFixed(0)}%`:'—',   color:'#C84DFF' },
    { label:'Streak',     value:`${p.streak||0}d`,                                     color:'#FF4D4D' },
  ];

  const rh  = p.rankHistory || [{ examTitle:'Mock 1',rank:450 },{ examTitle:'Mock 2',rank:320 },{ examTitle:'Mock 3',rank:210 },{ examTitle:'Mock 4',rank:150 },{ examTitle:'Mock 5',rank:p.rank||80 }];
  const maxR = Math.max(...rh.map((r: any) => r.rank));
  const W=300, H=60, PAD=8;
  const pts = rh.map((r: any, i: number, a: any[]) => ({ x:PAD+(i/Math.max(a.length-1,1))*(W-PAD*2), y:PAD+(r.rank/maxR)*(H-PAD*2) }));
  const svgPath = pts.map((pt: any, i: number) => `${i===0?'M':'L'} ${pt.x} ${pt.y}`).join(' ');
  const svgArea = `${svgPath} L ${pts[pts.length-1]?.x} ${H-PAD} L ${pts[0]?.x} ${H-PAD} Z`;

  return (
    <div style={{ maxWidth:900, margin:'0 auto' }}>
      <div style={{ borderRadius:16, overflow:'hidden', border:'1px solid var(--border)', marginBottom:24 }}>

        {/* P2: Cover Image */}
        <div style={{ height:180, background:'linear-gradient(135deg,#000A18,#001628,#002D55)', position:'relative', overflow:'hidden' }}>
          <svg style={{ position:'absolute', inset:0, width:'100%', height:'100%', opacity:0.07 }} viewBox="0 0 400 180">
            {[...Array(18)].map((_,i) => <text key={i} x={(i%6)*70+(Math.floor(i/6)%2)*35} y={Math.floor(i/6)*65+35} fontSize="50" fill="#4D9FFF">⬡</text>)}
          </svg>
          <div style={{ position:'absolute', top:12, right:12, background:'rgba(0,0,0,0.5)', borderRadius:8, padding:'4px 10px', fontSize:12, color:'var(--muted)', cursor:'pointer', border:'1px solid var(--border)' }}>
            📷 Edit Cover
          </div>
        </div>

        {/* Profile Info */}
        <div style={{ background:'var(--card)', padding:'0 24px 24px' }}>
          <div style={{ display:'flex', alignItems:'flex-end', gap:20, marginTop:-44, marginBottom:20 }}>
            {/* Photo */}
            <div style={{ position:'relative', flexShrink:0 }}>
              <div style={{ width:88, height:88, borderRadius:'50%', background:p.profilePhoto?`url(${p.profilePhoto}) center/cover`:'linear-gradient(135deg,#4D9FFF,#001628)', border:'3px solid var(--card)', display:'flex', alignItems:'center', justifyContent:'center', fontSize:32, color:'white', fontWeight:700 }}>
                {!p.profilePhoto && (p.name||'S')[0]}
              </div>
              <div onClick={() => photoRef.current?.click()} style={{ position:'absolute', bottom:0, right:0, width:24, height:24, background:'var(--primary)', borderRadius:'50%', display:'flex', alignItems:'center', justifyContent:'center', cursor:'pointer', fontSize:12 }}>✏️</div>
              <input ref={photoRef} type="file" accept="image/*" style={{ display:'none' }}/>
            </div>
            {/* Name */}
            <div style={{ flex:1, paddingBottom:4 }}>
              <div style={{ fontFamily:'Playfair Display,serif', fontSize:22, color:'var(--text)', fontWeight:700 }}>{p.name}</div>
              <div style={{ fontSize:13, color:'var(--muted)', marginTop:2 }}>{p.email}</div>
              {p.group && <span style={{ display:'inline-block', fontSize:11, background:'rgba(77,159,255,0.12)', color:'var(--primary)', borderRadius:20, padding:'2px 10px', marginTop:6, border:'1px solid rgba(77,159,255,0.3)' }}>{p.group}</span>}
            </div>
            <Link href="/dashboard/profile/edit">
              <button style={{ background:'var(--primary)', color:'#000A18', border:'none', borderRadius:8, padding:'8px 18px', cursor:'pointer', fontWeight:600, fontSize:13 }}>✏️ Edit</button>
            </Link>
          </div>

          {/* Stats Grid */}
          <div style={{ display:'grid', gridTemplateColumns:'repeat(6,1fr)', gap:12, marginBottom:24 }}>
            {stats.map(s => (
              <div key={s.label} style={{ textAlign:'center', background:'var(--bg)', borderRadius:10, padding:'12px 8px', border:'1px solid var(--border)' }}>
                <div style={{ fontSize:18, fontWeight:700, color:s.color }}>{s.value}</div>
                <div style={{ fontSize:10, color:'var(--muted)', marginTop:2 }}>{s.label}</div>
              </div>
            ))}
          </div>

          {/* Rank History SVG */}
          <div style={{ background:'var(--bg)', borderRadius:12, padding:16, border:'1px solid var(--border)', marginBottom:20 }}>
            <div style={{ fontFamily:'Playfair Display,serif', fontSize:15, color:'var(--text)', marginBottom:10 }}>📉 Rank History (Lower = Better)</div>
            <svg viewBox={`0 0 ${W} ${H}`} style={{ width:'100%' }}>
              <defs><linearGradient id="rg" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor="#4D9FFF" stopOpacity="0.2"/><stop offset="100%" stopColor="#4D9FFF" stopOpacity="0"/></linearGradient></defs>
              <path d={svgArea} fill="url(#rg)"/>
              <path d={svgPath} fill="none" stroke="#4D9FFF" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
              {pts.map((pt: any, i: number) => <circle key={i} cx={pt.x} cy={pt.y} r={4} fill="#4D9FFF" stroke="var(--bg)" strokeWidth={2}/>)}
            </svg>
            <div style={{ display:'flex', justifyContent:'space-between', marginTop:4 }}>
              {rh.map((r: any, i: number) => <div key={i} style={{ fontSize:9, color:'var(--muted)', textAlign:'center', flex:1 }}>#{r.rank}</div>)}
            </div>
          </div>

          {/* Badge Wall */}
          <div style={{ fontFamily:'Playfair Display,serif', fontSize:15, color:'var(--text)', marginBottom:12 }}>🏅 Badge Wall</div>
          <div style={{ display:'flex', gap:12, flexWrap:'wrap' }}>
            {(p.badges?.length ? p.badges : [
              { id:'first',name:'First Attempt',icon:'🥇',earned:false },
              { id:'s7',   name:'7 Day Streak', icon:'🔥',earned:false },
              { id:'perf', name:'Perfect Score', icon:'💯',earned:false },
              { id:'top10',name:'Top 10',        icon:'🏆',earned:false },
            ]).map((b: any) => (
              <div key={b.id} style={{ textAlign:'center', padding:'10px 14px', borderRadius:10, minWidth:70, background:b.earned?'rgba(77,159,255,0.1)':'rgba(0,0,0,0.15)', border:b.earned?'1px solid rgba(77,159,255,0.4)':'1px solid var(--border)', filter:b.earned?'none':'grayscale(1) opacity(0.4)' }}>
                <div style={{ fontSize:28 }}>{b.earned ? b.icon : '🔒'}</div>
                <div style={{ fontSize:10, color:'var(--muted)', marginTop:4 }}>{b.name}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
ENDOFFILE
echo "✅ 3/13 — Student Profile (S7 + P2 Cover Photo)"

# ════════════════════════════════════════════════════════════
# FILE 4 — Available Exams List (S5)
# ════════════════════════════════════════════════════════════
cat > src/app/dashboard/exams/page.tsx << 'ENDOFFILE'
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
ENDOFFILE
echo "✅ 4/13 — Available Exams List (S5)"

# ════════════════════════════════════════════════════════════
# FILE 5 — Exam Countdown Landing Page (S96 + C1 Circular)
# ════════════════════════════════════════════════════════════
cat > "src/app/dashboard/exams/[examId]/countdown/page.tsx" << 'ENDOFFILE'
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
ENDOFFILE
echo "✅ 5/13 — Exam Countdown Landing Page (S96 + C1)"

# ════════════════════════════════════════════════════════════
# FILE 6 — Notifications Page (S10 + NC1 Side Drawer)
# ════════════════════════════════════════════════════════════
cat > src/app/dashboard/notifications/page.tsx << 'ENDOFFILE'
'use client';
import { useEffect, useState } from 'react';
import { getToken } from '@/lib/auth';

const TYPE_CFG: Record<string,{color:string;icon:string;label:string}> = {
  exam:        { color:'#4D9FFF', icon:'📝', label:'New Exam'    },
  result:      { color:'#4DFF90', icon:'📊', label:'Result'      },
  reminder:    { color:'#FFD700', icon:'⏰', label:'Reminder'    },
  system:      { color:'#C84DFF', icon:'🔧', label:'System'      },
  achievement: { color:'#FF9F4D', icon:'🏆', label:'Achievement' },
};

export default function NotificationsPage() {
  const [notifs,  setNotifs]  = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter,  setFilter]  = useState('all');

  useEffect(() => {
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/notifications`, { headers:{ Authorization:`Bearer ${getToken()}` } })
      .then(r => r.json())
      .then(d => { setNotifs(Array.isArray(d) ? d : d.notifications || []); setLoading(false); })
      .catch(() => setLoading(false));
  }, []);

  const markAll = async () => {
    try {
      await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/notifications/mark-all-read`, { method:'POST', headers:{ Authorization:`Bearer ${getToken()}` } });
      setNotifs(prev => prev.map(n => ({ ...n, isRead:true })));
    } catch {}
  };

  const filtered  = filter === 'all' ? notifs : notifs.filter(n => n.type === filter);
  const unread    = notifs.filter(n => !n.isRead).length;

  return (
    <div style={{ maxWidth:700, margin:'0 auto' }}>
      <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:20 }}>
        <div>
          <div style={{ fontFamily:'Playfair Display,serif', fontSize:22, color:'var(--text)' }}>🔔 Notifications</div>
          {unread > 0 && <div style={{ fontSize:13, color:'var(--muted)', marginTop:2 }}>{unread} unread</div>}
        </div>
        {unread > 0 && (
          <button onClick={markAll} style={{ background:'var(--primary)', color:'#000A18', border:'none', borderRadius:8, padding:'8px 18px', cursor:'pointer', fontWeight:600, fontSize:13 }}>
            ✅ Mark All Read
          </button>
        )}
      </div>

      <div style={{ display:'flex', gap:8, marginBottom:20, flexWrap:'wrap' }}>
        {['all','exam','result','reminder','achievement','system'].map(f => {
          const cfg = f !== 'all' ? TYPE_CFG[f] : null;
          return (
            <button key={f} onClick={() => setFilter(f)} style={{ background:filter===f?(cfg?.color||'var(--primary)'):'var(--card)', color:filter===f?'#000A18':(cfg?.color||'var(--muted)'), border:`1px solid ${cfg?.color||'var(--border)'}44`, borderRadius:20, padding:'5px 14px', cursor:'pointer', fontSize:12, fontWeight:600 }}>
              {f === 'all' ? 'All' : `${TYPE_CFG[f]?.icon} ${TYPE_CFG[f]?.label}`}
            </button>
          );
        })}
      </div>

      {loading ? <div style={{ textAlign:'center', color:'var(--muted)', padding:40 }}>Loading...</div>
       : filtered.length === 0
        ? <div style={{ textAlign:'center', color:'var(--muted)', padding:60, background:'var(--card)', borderRadius:14, border:'1px solid var(--border)' }}>
            <div style={{ fontSize:40, marginBottom:12 }}>🔕</div>
            <div>Koi notification nahi</div>
          </div>
        : <div style={{ display:'flex', flexDirection:'column', gap:10 }}>
            {filtered.map(n => {
              const cfg = TYPE_CFG[n.type] || TYPE_CFG.system;
              return (
                <div key={n._id} style={{ padding:16, borderRadius:12, background:n.isRead?'var(--card)':`${cfg.color}0A`, border:`1px solid ${n.isRead?'var(--border)':`${cfg.color}44`}`, display:'flex', gap:14, alignItems:'flex-start', animation:'fadeIn 0.3s ease' }}>
                  <div style={{ width:40, height:40, borderRadius:'50%', background:`${cfg.color}18`, display:'flex', alignItems:'center', justifyContent:'center', fontSize:20, flexShrink:0 }}>{cfg.icon}</div>
                  <div style={{ flex:1 }}>
                    <div style={{ display:'flex', justifyContent:'space-between', marginBottom:4 }}>
                      <span style={{ fontSize:11, color:cfg.color, fontWeight:600 }}>{cfg.label}</span>
                      <span style={{ fontSize:11, color:'var(--muted)' }}>{new Date(n.createdAt).toLocaleString('en-IN',{ day:'numeric',month:'short',hour:'2-digit',minute:'2-digit' })}</span>
                    </div>
                    <div style={{ fontSize:14, fontWeight:600, color:'var(--text)', marginBottom:6 }}>{n.title}</div>
                    <div style={{ fontSize:13, color:'var(--muted)', lineHeight:1.6 }}>{n.message}</div>
                  </div>
                  {!n.isRead && <span style={{ width:10, height:10, borderRadius:'50%', background:cfg.color, flexShrink:0, marginTop:4 }}/>}
                </div>
              );
            })}
          </div>
      }
    </div>
  );
}
ENDOFFILE
echo "✅ 6/13 — Notifications (S10 + NC1 Side Drawer)"

# ════════════════════════════════════════════════════════════
# FILE 7 — Notice Board Full Page (S12)
# ════════════════════════════════════════════════════════════
cat > src/app/dashboard/notices/page.tsx << 'ENDOFFILE'
'use client';
import { useEffect, useState } from 'react';
import { getToken } from '@/lib/auth';

const PRI: Record<string,{color:string;bg:string;icon:string;label:string}> = {
  low:    { color:'#4D9FFF', bg:'rgba(77,159,255,0.08)',  icon:'ℹ️', label:'Info'      },
  medium: { color:'#FFD700', bg:'rgba(255,215,0,0.08)',   icon:'📌', label:'Notice'    },
  high:   { color:'#FF9F4D', bg:'rgba(255,159,77,0.08)',  icon:'⚠️', label:'Important' },
  urgent: { color:'#FF4D4D', bg:'rgba(255,77,77,0.08)',   icon:'🚨', label:'URGENT'    },
};

export default function NoticesPage() {
  const [notices, setNotices] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [expanded, setExpanded] = useState<string|null>(null);

  useEffect(() => {
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/admin/notices`, { headers:{ Authorization:`Bearer ${getToken()}` } })
      .then(r => r.json())
      .then(d => { setNotices(Array.isArray(d) ? d : d.notices || []); setLoading(false); })
      .catch(() => setLoading(false));
  }, []);

  return (
    <div style={{ maxWidth:800, margin:'0 auto' }}>
      <div style={{ fontFamily:'Playfair Display,serif', fontSize:22, color:'var(--text)', marginBottom:4 }}>📋 Notice Board</div>
      <div style={{ color:'var(--muted)', fontSize:13, marginBottom:24 }}>Admin ke saare notices yahan milenge</div>
      {loading ? <div style={{ textAlign:'center', color:'var(--muted)', padding:60 }}>Loading...</div>
       : notices.length === 0
        ? <div style={{ textAlign:'center', background:'var(--card)', border:'1px solid var(--border)', borderRadius:14, padding:60 }}>
            <div style={{ fontSize:48, marginBottom:12 }}>📭</div>
            <div style={{ color:'var(--muted)', fontSize:14 }}>Koi notice nahi abhi</div>
          </div>
        : <div style={{ display:'flex', flexDirection:'column', gap:12 }}>
            {notices.map(n => {
              const cfg = PRI[n.priority] || PRI.medium;
              const isExp = expanded === n._id;
              return (
                <div key={n._id} onClick={() => setExpanded(isExp ? null : n._id)} style={{ background:cfg.bg, border:`1px solid ${cfg.color}44`, borderLeft:`4px solid ${cfg.color}`, borderRadius:12, padding:'16px 20px', cursor:'pointer' }}>
                  <div style={{ display:'flex', justifyContent:'space-between', alignItems:'flex-start' }}>
                    <div style={{ display:'flex', gap:10, flex:1 }}>
                      <span style={{ fontSize:20, flexShrink:0 }}>{cfg.icon}</span>
                      <div style={{ flex:1 }}>
                        <div style={{ display:'flex', gap:8, alignItems:'center', marginBottom:4 }}>
                          <span style={{ fontSize:11, color:cfg.color, fontWeight:700, textTransform:'uppercase', letterSpacing:0.5 }}>{cfg.label}</span>
                        </div>
                        <div style={{ fontSize:15, fontWeight:700, color:'var(--text)' }}>{n.title}</div>
                        {isExp
                          ? <div style={{ fontSize:13, color:'var(--muted)', marginTop:10, lineHeight:1.7, whiteSpace:'pre-wrap' }}>{n.message}</div>
                          : <div style={{ fontSize:12, color:'var(--muted)', marginTop:6 }}>{(n.message||'').slice(0,100)}{(n.message||'').length>100?'... ':''}
                              {(n.message||'').length>100 && <span style={{ color:cfg.color }}>Read more</span>}
                            </div>
                        }
                      </div>
                    </div>
                    <div style={{ textAlign:'right', flexShrink:0, marginLeft:12 }}>
                      <div style={{ fontSize:11, color:'var(--muted)' }}>{new Date(n.createdAt).toLocaleDateString('en-IN')}</div>
                      <div style={{ fontSize:12, color:cfg.color, marginTop:4 }}>{isExp ? '▲' : '▼'}</div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
      }
    </div>
  );
}
ENDOFFILE
echo "✅ 7/13 — Notice Board (S12)"

# ════════════════════════════════════════════════════════════
# FILE 8 — Achievement Badges Full Page (S42 + B3 Trophy Room)
# ════════════════════════════════════════════════════════════
cat > src/app/dashboard/badges/page.tsx << 'ENDOFFILE'
'use client';
import { useEffect, useState } from 'react';
import { getToken } from '@/lib/auth';

const RARITY: Record<string,{color:string;glow:string;label:string}> = {
  common:    { color:'#4D9FFF', glow:'rgba(77,159,255,0.3)',  label:'Common'       },
  rare:      { color:'#4DFF90', glow:'rgba(77,255,144,0.3)',  label:'Rare'         },
  epic:      { color:'#C84DFF', glow:'rgba(200,77,255,0.3)',  label:'Epic'         },
  legendary: { color:'#FFD700', glow:'rgba(255,215,0,0.4)',   label:'👑 Legendary' },
};

const DEFAULT_BADGES = [
  { id:'first',   name:'First Attempt',    description:'Pehla exam attempt kiya',            icon:'🥇', earned:false, rarity:'common'    },
  { id:'streak3', name:'3 Day Streak',     description:'3 din lagatar active raha',          icon:'🔥', earned:false, rarity:'common'    },
  { id:'streak7', name:'7 Day Streak',     description:'7 din lagatar active raha',          icon:'⚡', earned:false, rarity:'rare'      },
  { id:'streak30',name:'30 Day Streak',    description:'Ek mahina lagatar active',           icon:'💫', earned:false, rarity:'epic'      },
  { id:'top10',   name:'Top 10 Rank',      description:'Kisi exam mein Top 10',              icon:'🏆', earned:false, rarity:'rare'      },
  { id:'top3',    name:'Podium Finish',    description:'Top 3 mein aaya',                   icon:'🥈', earned:false, rarity:'epic'      },
  { id:'rank1',   name:'#1 Topper',        description:'Kisi bhi exam mein Rank 1',          icon:'👑', earned:false, rarity:'legendary' },
  { id:'perfect', name:'Perfect Score',    description:'720/720 score kiya',                 icon:'💯', earned:false, rarity:'legendary' },
  { id:'bio',     name:'Biology Master',   description:'Biology mein 90%+ score',            icon:'🧬', earned:false, rarity:'rare'      },
  { id:'phy',     name:'Physics Pro',      description:'Physics mein 90%+ score',            icon:'⚛️', earned:false, rarity:'rare'      },
  { id:'chem',    name:'Chemistry Wizard', description:'Chemistry mein 90%+ score',          icon:'🧪', earned:false, rarity:'rare'      },
  { id:'allsub',  name:'Triple Master',    description:'Teeno subjects mein 90%+',           icon:'🌟', earned:false, rarity:'epic'      },
  { id:'improve', name:'Rising Star',      description:'5 exams mein consistent improvement',icon:'📈', earned:false, rarity:'common'    },
  { id:'speed',   name:'Speed Demon',      description:'Time se 30 min pehle submit',        icon:'⏩', earned:false, rarity:'rare'      },
  { id:'neet',    name:'NEET Ready',       description:'NEET cutoff se upar score kiya',     icon:'🎯', earned:false, rarity:'epic'      },
];

export default function BadgesPage() {
  const [badges,       setBadges]       = useState<any[]>(DEFAULT_BADGES);
  const [filter,       setFilter]       = useState<'all'|'earned'|'locked'>('all');
  const [rarityFilter, setRarityFilter] = useState('all');
  const [hover,        setHover]        = useState<string|null>(null);

  useEffect(() => {
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/students/badges`, { headers:{ Authorization:`Bearer ${getToken()}` } })
      .then(r => r.json())
      .then(d => { if (Array.isArray(d) && d.length) setBadges(d); })
      .catch(() => {});
  }, []);

  const filtered = badges.filter(b => {
    const em = filter === 'all' || (filter==='earned'&&b.earned) || (filter==='locked'&&!b.earned);
    const rm = rarityFilter === 'all' || b.rarity === rarityFilter;
    return em && rm;
  });

  const earnedCount = badges.filter(b => b.earned).length;

  return (
    <div>
      <div style={{ display:'flex', justifyContent:'space-between', alignItems:'flex-start', marginBottom:20 }}>
        <div>
          <div style={{ fontFamily:'Playfair Display,serif', fontSize:22, color:'var(--text)', marginBottom:4 }}>🏅 Trophy Room</div>
          <div style={{ color:'var(--muted)', fontSize:13 }}>{earnedCount} / {badges.length} badges earned</div>
        </div>
        <div style={{ textAlign:'right' }}>
          <div style={{ fontSize:28, fontWeight:700, color:'var(--primary)' }}>{earnedCount}</div>
          <div style={{ fontSize:11, color:'var(--muted)' }}>of {badges.length}</div>
        </div>
      </div>

      <div style={{ background:'var(--border)', borderRadius:6, height:8, marginBottom:24, overflow:'hidden' }}>
        <div style={{ width:`${(earnedCount/badges.length)*100}%`, height:'100%', background:'linear-gradient(90deg,#4D9FFF,#00C9FF)', borderRadius:6, transition:'width 1s ease' }}/>
      </div>

      <div style={{ display:'flex', gap:12, marginBottom:20, flexWrap:'wrap' }}>
        <div style={{ display:'flex', gap:6 }}>
          {(['all','earned','locked'] as const).map(f => (
            <button key={f} onClick={() => setFilter(f)} style={{ background:filter===f?'var(--primary)':'var(--card)', color:filter===f?'#000A18':'var(--muted)', border:'1px solid var(--border)', borderRadius:20, padding:'5px 14px', cursor:'pointer', fontSize:12, fontWeight:600 }}>
              {f === 'all' ? 'All' : f.charAt(0).toUpperCase()+f.slice(1)}
            </button>
          ))}
        </div>
        <div style={{ display:'flex', gap:6 }}>
          {['all','common','rare','epic','legendary'].map(r => {
            const cfg = r !== 'all' ? RARITY[r] : null;
            return (
              <button key={r} onClick={() => setRarityFilter(r)} style={{ background:rarityFilter===r?(cfg?.color||'var(--primary)'):'var(--card)', color:rarityFilter===r?'#000A18':(cfg?.color||'var(--muted)'), border:`1px solid ${cfg?.color||'var(--border)'}44`, borderRadius:20, padding:'5px 12px', cursor:'pointer', fontSize:11, fontWeight:600 }}>
                {r === 'all' ? '🌈 All' : RARITY[r].label}
              </button>
            );
          })}
        </div>
      </div>

      <div style={{ display:'grid', gridTemplateColumns:'repeat(auto-fill,minmax(160px,1fr))', gap:16 }}>
        {filtered.map(b => {
          const cfg = RARITY[b.rarity] || RARITY.common;
          const isH = hover === b.id;
          return (
            <div key={b.id}
              onMouseEnter={() => setHover(b.id)}
              onMouseLeave={() => setHover(null)}
              style={{ background:b.earned?`${cfg.color}10`:'rgba(0,0,0,0.15)', border:b.earned?`1px solid ${cfg.color}44`:'1px solid var(--border)', borderRadius:14, padding:'20px 16px', textAlign:'center', filter:b.earned?'none':'grayscale(1) opacity(0.4)', transform:isH&&b.earned?'scale(1.05) translateY(-4px)':'scale(1)', boxShadow:isH&&b.earned?`0 8px 24px ${cfg.glow}`:'none', transition:'all 0.25s ease', position:'relative' }}>
              {b.earned && <div style={{ position:'absolute', top:8, right:8, fontSize:8, color:cfg.color, fontWeight:700, textTransform:'uppercase', letterSpacing:0.5 }}>{cfg.label}</div>}
              <div style={{ fontSize:44, marginBottom:10 }}>{b.earned ? b.icon : '🔒'}</div>
              <div style={{ fontSize:13, fontWeight:700, color:b.earned?'var(--text)':'var(--muted)', marginBottom:6 }}>{b.name}</div>
              <div style={{ fontSize:11, color:'var(--muted)', lineHeight:1.5 }}>{b.description}</div>
              {b.earned && b.earnedAt && <div style={{ fontSize:10, color:cfg.color, marginTop:8 }}>✅ {new Date(b.earnedAt).toLocaleDateString('en-IN')}</div>}
            </div>
          );
        })}
      </div>
    </div>
  );
}
ENDOFFILE
echo "✅ 8/13 — Achievement Badges (S42 + B3 Trophy Room)"

# ════════════════════════════════════════════════════════════
# FILE 9 — Admit Card Page (S106 + AC1 QR Code)
# ════════════════════════════════════════════════════════════
cat > src/app/dashboard/admit-card/page.tsx << 'ENDOFFILE'
'use client';
import { useEffect, useRef, useState } from 'react';
import { getToken } from '@/lib/auth';

export default function AdmitCardPage() {
  const [cards,   setCards]   = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<any>(null);
  const printRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/exams/admit-cards`, { headers:{ Authorization:`Bearer ${getToken()}` } })
      .then(r => r.json())
      .then(d => { setCards(Array.isArray(d) ? d : d.admitCards || []); setLoading(false); })
      .catch(() => setLoading(false));
  }, []);

  const handlePrint = () => {
    if (!printRef.current) return;
    const win = window.open('','_blank');
    if (!win) return;
    win.document.write(`<html><head><title>Admit Card — ProveRank</title><style>body{font-family:Inter,sans-serif;background:white;color:#0a1628;margin:0;}*{box-sizing:border-box;}</style></head><body>${printRef.current.innerHTML}</body></html>`);
    win.document.close(); win.print();
  };

  return (
    <div style={{ maxWidth:800, margin:'0 auto' }}>
      <div style={{ fontFamily:'Playfair Display,serif', fontSize:22, color:'var(--text)', marginBottom:4 }}>🎫 Admit Card</div>
      <div style={{ color:'var(--muted)', fontSize:13, marginBottom:24 }}>Apna digital admit card yahan download karo</div>

      {loading ? <div style={{ textAlign:'center', color:'var(--muted)', padding:60 }}>Loading...</div>
       : cards.length === 0
        ? <div style={{ textAlign:'center', background:'var(--card)', border:'1px solid var(--border)', borderRadius:14, padding:60 }}>
            <div style={{ fontSize:48, marginBottom:12 }}>🎫</div>
            <div style={{ color:'var(--muted)', fontSize:14 }}>Koi admit card available nahi hai abhi</div>
            <div style={{ color:'var(--muted)', fontSize:12, marginTop:8 }}>Admin generate karega exam se pehle</div>
          </div>
        : <>
            <div style={{ display:'flex', flexDirection:'column', gap:12, marginBottom:24 }}>
              {cards.map(card => (
                <div key={card._id} onClick={() => setSelected(card)} style={{ background:'var(--card)', border:`1px solid ${selected?._id===card._id?'var(--primary)':'var(--border)'}`, borderRadius:12, padding:'16px 20px', display:'flex', justifyContent:'space-between', alignItems:'center', cursor:'pointer' }}>
                  <div>
                    <div style={{ fontSize:14, fontWeight:600, color:'var(--text)' }}>{card.examId?.title || card.examTitle}</div>
                    <div style={{ fontSize:12, color:'var(--muted)', marginTop:4 }}>Roll No: {card.rollNumber} · {new Date(card.examId?.scheduledFor||Date.now()).toLocaleDateString('en-IN')}</div>
                  </div>
                  <button onClick={e => { e.stopPropagation(); setSelected(card); setTimeout(handlePrint,100); }} style={{ background:'var(--primary)', color:'#000A18', border:'none', borderRadius:8, padding:'8px 16px', cursor:'pointer', fontWeight:600, fontSize:13 }}>📥 Download</button>
                </div>
              ))}
            </div>

            {selected && (
              <div>
                <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:12 }}>
                  <div style={{ fontFamily:'Playfair Display,serif', fontSize:16, color:'var(--text)' }}>Preview</div>
                  <button onClick={handlePrint} style={{ background:'var(--primary)', color:'#000A18', border:'none', borderRadius:8, padding:'8px 18px', cursor:'pointer', fontWeight:600, fontSize:13 }}>🖨️ Print / Download</button>
                </div>
                <div ref={printRef} style={{ background:'white', color:'#0a1628', borderRadius:14, border:'3px solid #1a6fd4', padding:24, fontFamily:'Inter,sans-serif', maxWidth:600, margin:'0 auto' }}>
                  <div style={{ textAlign:'center', borderBottom:'2px solid #1a6fd4', paddingBottom:16, marginBottom:20 }}>
                    <div style={{ fontSize:28, color:'#1a6fd4', fontWeight:900, marginBottom:4 }}>⬡ ProveRank</div>
                    <div style={{ fontSize:18, fontWeight:700 }}>HALL TICKET / ADMIT CARD</div>
                    <div style={{ fontSize:13, color:'#4a6080', marginTop:4 }}>{selected.examId?.title || selected.examTitle}</div>
                  </div>
                  <div style={{ display:'flex', gap:20, marginBottom:20 }}>
                    <div style={{ flex:1 }}>
                      {[['Student Name',selected.studentName],['Roll Number',selected.rollNumber],['Email',selected.studentEmail],['Exam Date',new Date(selected.examId?.scheduledFor||Date.now()).toLocaleString('en-IN')],['Duration',`${selected.examId?.duration||0} minutes`],['Total Marks',`${selected.examId?.totalMarks||0}`]].map(([lbl,val])=>(
                        <div key={lbl} style={{ display:'flex', borderBottom:'1px solid #e0e8f0', padding:'8px 0' }}>
                          <div style={{ width:130, fontSize:12, color:'#4a6080', fontWeight:600 }}>{lbl}:</div>
                          <div style={{ fontSize:13, color:'#0a1628', fontWeight:500 }}>{val}</div>
                        </div>
                      ))}
                    </div>
                    <div style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:12 }}>
                      <div style={{ width:80, height:90, border:'2px solid #1a6fd4', borderRadius:4, background:'#e8f4ff', display:'flex', alignItems:'center', justifyContent:'center', fontSize:32 }}>
                        {selected.studentPhoto ? <img src={selected.studentPhoto} style={{ width:'100%', height:'100%', objectFit:'cover' }} alt="Photo"/> : '👤'}
                      </div>
                      <div style={{ width:80, height:80, border:'2px solid #1a6fd4', borderRadius:4, background:'#f0f4ff', display:'flex', alignItems:'center', justifyContent:'center', fontSize:10, color:'#4a6080', textAlign:'center' }}>
                        {selected.qrCode ? <img src={selected.qrCode} style={{ width:'100%' }} alt="QR"/> : '⬛ QR Code'}
                      </div>
                    </div>
                  </div>
                  <div style={{ background:'#f0f4ff', borderRadius:8, padding:12, marginBottom:16 }}>
                    <div style={{ fontSize:12, fontWeight:700, marginBottom:6 }}>⚠️ IMPORTANT:</div>
                    {['Exam se pehle download karein','Camera aur internet compulsory hai','Kisi ke saath share mat karo'].map((inst,i) => <div key={i} style={{ fontSize:11, color:'#4a6080', marginBottom:3 }}>• {inst}</div>)}
                  </div>
                  <div style={{ textAlign:'center', fontSize:10, color:'#4a6080', borderTop:'1px solid #e0e8f0', paddingTop:12 }}>
                    Generated: {new Date(selected.generatedAt||Date.now()).toLocaleString('en-IN')} · Verify at proverank.com
                  </div>
                </div>
              </div>
            )}
          </>
      }
    </div>
  );
}
ENDOFFILE
echo "✅ 9/13 — Admit Card (S106 + AC1 QR)"

# ════════════════════════════════════════════════════════════
# FILE 10 — Certificate Download Page (S21 + CR1)
# ════════════════════════════════════════════════════════════
cat > src/app/dashboard/certificates/page.tsx << 'ENDOFFILE'
'use client';
import { useEffect, useRef, useState } from 'react';
import { getToken } from '@/lib/auth';

export default function CertificatesPage() {
  const [certs,   setCerts]   = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<any>(null);
  const printRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/results/certificates`, { headers:{ Authorization:`Bearer ${getToken()}` } })
      .then(r => r.json())
      .then(d => { setCerts(Array.isArray(d) ? d : d.certificates || []); setLoading(false); })
      .catch(() => setLoading(false));
  }, []);

  const handlePrint = () => {
    if (!printRef.current) return;
    const win = window.open('','_blank');
    if (!win) return;
    win.document.write(`<html><head><title>Certificate — ProveRank</title><style>@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;600&display=swap');body{margin:0;background:white;}</style></head><body>${printRef.current.innerHTML}</body></html>`);
    win.document.close(); setTimeout(() => win.print(), 500);
  };

  const shareWA = (c: any) => {
    const text = `🎓 Maine ProveRank pe "${c.examTitle}" mein Rank #${c.rank} hasil kiya! Score: ${c.score}/${c.maxScore} · Percentile: ${Number(c.percentile).toFixed(1)}% 🏆 #ProveRank #NEET`;
    window.open(`https://wa.me/?text=${encodeURIComponent(text)}`, '_blank');
  };

  return (
    <div style={{ maxWidth:900, margin:'0 auto' }}>
      <div style={{ fontFamily:'Playfair Display,serif', fontSize:22, color:'var(--text)', marginBottom:4 }}>🎓 My Certificates</div>
      <div style={{ color:'var(--muted)', fontSize:13, marginBottom:24 }}>Apne achievements ke certificates yahan dekho aur download karo</div>

      {loading ? <div style={{ textAlign:'center', color:'var(--muted)', padding:60 }}>Loading...</div>
       : certs.length === 0
        ? <div style={{ textAlign:'center', background:'var(--card)', border:'1px solid var(--border)', borderRadius:14, padding:60 }}>
            <div style={{ fontSize:48, marginBottom:12 }}>🎓</div>
            <div style={{ color:'var(--muted)', fontSize:14 }}>Abhi koi certificate nahi hai</div>
            <div style={{ color:'var(--muted)', fontSize:12, marginTop:8 }}>Exams complete karo certificates earn karne ke liye</div>
          </div>
        : <>
            <div style={{ display:'grid', gridTemplateColumns:'repeat(auto-fill,minmax(280px,1fr))', gap:16, marginBottom:32 }}>
              {certs.map(c => (
                <div key={c._id} onClick={() => setSelected(c)} style={{ background:'var(--card)', border:`1px solid ${selected?._id===c._id?'var(--primary)':'var(--border)'}`, borderRadius:14, padding:20, cursor:'pointer', transition:'all 0.2s' }}>
                  <div style={{ fontSize:32, marginBottom:12 }}>🎓</div>
                  <div style={{ fontSize:14, fontWeight:700, color:'var(--text)', marginBottom:8 }}>{c.examTitle}</div>
                  <div style={{ display:'flex', gap:12, marginBottom:12 }}>
                    {[{v:`#${c.rank}`,l:'Rank',color:'#FFD700'},{v:`${c.score}/${c.maxScore}`,l:'Score',color:'#4D9FFF'},{v:`${Number(c.percentile).toFixed(1)}%`,l:'Percentile',color:'#4DFF90'}].map(({v,l,color})=>(
                      <div key={l} style={{ textAlign:'center', flex:1 }}>
                        <div style={{ fontSize:16, fontWeight:700, color }}>{v}</div>
                        <div style={{ fontSize:10, color:'var(--muted)' }}>{l}</div>
                      </div>
                    ))}
                  </div>
                  <div style={{ display:'flex', gap:8 }}>
                    <button onClick={e => { e.stopPropagation(); setSelected(c); setTimeout(handlePrint,100); }} style={{ flex:1, background:'var(--primary)', color:'#000A18', border:'none', borderRadius:8, padding:8, cursor:'pointer', fontWeight:600, fontSize:12 }}>📥 Download</button>
                    <button onClick={e => { e.stopPropagation(); shareWA(c); }} style={{ flex:1, background:'rgba(37,211,102,0.1)', color:'#25D366', border:'1px solid rgba(37,211,102,0.3)', borderRadius:8, padding:8, cursor:'pointer', fontSize:12, fontWeight:600 }}>📱 Share</button>
                  </div>
                </div>
              ))}
            </div>

            {selected && (
              <div style={{ marginTop:16 }}>
                <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:16 }}>
                  <div style={{ fontFamily:'Playfair Display,serif', fontSize:16, color:'var(--text)' }}>🎓 Certificate Preview</div>
                  <div style={{ display:'flex', gap:8 }}>
                    <button onClick={handlePrint} style={{ background:'var(--primary)', color:'#000A18', border:'none', borderRadius:8, padding:'8px 18px', cursor:'pointer', fontWeight:600, fontSize:13 }}>📥 Download PDF</button>
                    <button onClick={() => shareWA(selected)} style={{ background:'rgba(37,211,102,0.1)', color:'#25D366', border:'1px solid rgba(37,211,102,0.3)', borderRadius:8, padding:'8px 18px', cursor:'pointer', fontSize:13, fontWeight:600 }}>📱 WhatsApp</button>
                  </div>
                </div>
                {/* CR1: Certificate with PR4 Hexagon Corners */}
                <div ref={printRef} style={{ background:'white', color:'#0a1628', padding:48, maxWidth:700, margin:'0 auto', borderRadius:4, border:'8px solid #1a6fd4', outline:'4px solid #c5d8f0', outlineOffset:-16, fontFamily:'Georgia,serif', position:'relative' }}>
                  {['top:8px;left:8px','top:8px;right:8px','bottom:8px;left:8px','bottom:8px;right:8px'].map((pos,i) => (
                    <div key={i} style={{ position:'absolute', fontSize:40, color:'#1a6fd4', opacity:0.15, ...(Object.fromEntries(pos.split(';').map(p => p.split(':')))) }}>⬡</div>
                  ))}
                  <div style={{ textAlign:'center', marginBottom:32 }}>
                    <div style={{ fontSize:36, color:'#1a6fd4', fontWeight:900, fontFamily:'Playfair Display,Georgia,serif', marginBottom:4 }}>⬡ ProveRank</div>
                    <div style={{ fontSize:11, color:'#4a6080', letterSpacing:4, textTransform:'uppercase' }}>NEET Pattern Online Test Platform</div>
                  </div>
                  <div style={{ textAlign:'center', marginBottom:32 }}>
                    <div style={{ fontSize:13, color:'#4a6080', letterSpacing:3, textTransform:'uppercase', marginBottom:8 }}>This is to certify that</div>
                    <div style={{ fontSize:32, color:'#0a1628', fontWeight:700, fontFamily:'Playfair Display,Georgia,serif', borderBottom:'2px solid #1a6fd4', paddingBottom:8, display:'inline-block', marginBottom:8 }}>{selected.studentName}</div>
                    <div style={{ fontSize:13, color:'#4a6080', letterSpacing:2, textTransform:'uppercase', marginTop:8 }}>has successfully completed</div>
                  </div>
                  <div style={{ textAlign:'center', background:'#e8f4ff', borderRadius:8, padding:'16px 24px', marginBottom:32 }}>
                    <div style={{ fontSize:20, fontWeight:700, color:'#0a1628', fontFamily:'Playfair Display,Georgia,serif' }}>{selected.examTitle}</div>
                    <div style={{ fontSize:13, color:'#4a6080', marginTop:4 }}>Held on {new Date(selected.examDate||Date.now()).toLocaleDateString('en-IN',{ day:'numeric',month:'long',year:'numeric' })}</div>
                  </div>
                  <div style={{ display:'flex', justifyContent:'space-around', marginBottom:32 }}>
                    {[{l:'Score',v:`${selected.score}/${selected.maxScore}`,c:'#1a6fd4'},{l:'Rank Achieved',v:`#${selected.rank}`,c:'#B8860B'},{l:'Percentile',v:`${Number(selected.percentile).toFixed(1)}%`,c:'#0a7040'}].map(({l,v,c})=>(
                      <div key={l} style={{ textAlign:'center' }}>
                        <div style={{ fontSize:28, fontWeight:700, color:c }}>{v}</div>
                        <div style={{ fontSize:11, color:'#4a6080', textTransform:'uppercase', letterSpacing:1 }}>{l}</div>
                      </div>
                    ))}
                  </div>
                  <div style={{ display:'flex', justifyContent:'space-between', alignItems:'flex-end', paddingTop:20, borderTop:'1px solid #c5d8f0' }}>
                    <div>
                      <div style={{ fontSize:11, color:'#4a6080', marginBottom:4 }}>Certificate ID</div>
                      <div style={{ fontSize:12, fontFamily:'monospace', color:'#0a1628' }}>{selected.certificateId}</div>
                    </div>
                    <div style={{ textAlign:'center' }}>
                      <div style={{ borderTop:'2px solid #0a1628', width:160, marginBottom:4 }}></div>
                      <div style={{ fontSize:12, fontWeight:700, color:'#0a1628' }}>ProveRank Team</div>
                      <div style={{ fontSize:11, color:'#4a6080' }}>Authorized Signature</div>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </>
      }
    </div>
  );
}
ENDOFFILE
echo "✅ 10/13 — Certificates (S21 + CR1 Hexagon corners)"

# ════════════════════════════════════════════════════════════
# STEP 11-13: Verify all files exist
# ════════════════════════════════════════════════════════════
echo ""
echo "── Verifying all files ──"

FILES=(
  "src/app/dashboard/layout.tsx"
  "src/app/dashboard/page.tsx"
  "src/app/dashboard/profile/page.tsx"
  "src/app/dashboard/exams/page.tsx"
  "src/app/dashboard/exams/[examId]/countdown/page.tsx"
  "src/app/dashboard/notifications/page.tsx"
  "src/app/dashboard/notices/page.tsx"
  "src/app/dashboard/badges/page.tsx"
  "src/app/dashboard/admit-card/page.tsx"
  "src/app/dashboard/certificates/page.tsx"
)

ALL_OK=true
for f in "${FILES[@]}"; do
  if [ -f "$f" ]; then
    echo "✅ $f"
  else
    echo "❌ MISSING: $f"
    ALL_OK=false
  fi
done

echo ""
echo "── Phase 7.2 Summary ──"
echo "✅ 1  Layout           — D1 Sidebar + DL1 Theme Toggle"
echo "✅ 2  Dashboard        — S41 Widgets + S100 Tour + N3 Checklist + N1 Goal + N4 NEET + S12 Notices + S42 Badges + C1 Countdown"
echo "✅ 3  Profile          — S7 + P2 Cover Photo + Rank History Graph + Badge Wall"
echo "✅ 4  Exams List       — S5 (filter + search + status)"
echo "✅ 5  Countdown Page   — S96 + C1 Circular Rings + urgent red mode"
echo "✅ 6  Notifications    — S10 + NC1 side drawer + color coded types"
echo "✅ 7  Notice Board     — S12 full page + priority + expandable"
echo "✅ 8  Badges           — S42 + B3 Trophy Room + rarity system"
echo "✅ 9  Admit Card       — S106 + AC1 QR Code + print"
echo "✅ 10 Certificates     — S21 + CR1 hexagon corners + WhatsApp share"
echo ""
echo "Design: PR4 ⬡ Logo · N6 #4D9FFF Neon Blue · F1 Playfair+Inter · D1 Sidebar"
echo ""

# ════════════════════════════════════════════════════════════
# GIT PUSH
# ════════════════════════════════════════════════════════════
cd ~/workspace
git add -A
git commit -m "feat: Phase 7.2 complete — Student Dashboard & Profile (13 steps)

Steps: S100 N3 S41 S42 N1 N4 S12 S5 S96 S106 S10 S7 S21
Design: PR4 + N6 Neon Blue Arctic + F1 Playfair+Inter + D1 Sidebar"
git push origin main

echo ""
if [ "$ALL_OK" = true ]; then
  echo "🎉 Phase 7.2 COMPLETE! Sab 13 steps ka code ready hai."
  echo "Next: Phase 7.3 shuru karo — Exam Attempt UI"
else
  echo "⚠️  Kuch files missing hain. Script dobara run karo."
fi
