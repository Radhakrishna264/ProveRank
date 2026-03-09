'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { getToken, getRole, logout } from '@/lib/auth';
import PRLogo from '@/components/PRLogo';

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
          <PRLogo size={32} showName horizontal nameSize={17} />
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
