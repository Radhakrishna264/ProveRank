'use client';
import { useEffect, useState } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import { getToken, getRole, logout } from '@/lib/auth';

const NAV = [
  { href:'/admin', icon:'📊', label:'Dashboard' },
  { href:'/admin/students', icon:'👥', label:'Students' },
  { href:'/admin/exams', icon:'📝', label:'Exams' },
  { href:'/admin/questions', icon:'❓', label:'Questions' },
  { href:'/admin/results', icon:'📈', label:'Results' },
  { href:'/admin/announcements', icon:'📢', label:'Announcements' },
  { href:'/admin/settings', icon:'⚙️', label:'Settings' },
];

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [mounted, setMounted] = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(false);

  useEffect(() => {
    setMounted(true);
    const token = getToken();
    const role = getRole();
    if (!token) { router.push('/login'); return; }
    if (role !== 'admin' && role !== 'superadmin') { router.push('/dashboard'); return; }
  }, [router]);

  if (!mounted) return null;

  return (
    <div style={{minHeight:'100vh',background:'#000A18',fontFamily:'Inter,sans-serif',display:'flex'}}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600&display=swap');
        ::-webkit-scrollbar{width:4px} ::-webkit-scrollbar-track{background:#000A18} ::-webkit-scrollbar-thumb{background:#002D55;border-radius:2px}
        @keyframes fadeIn{from{opacity:0}to{opacity:1}}
      `}</style>

      {/* Mobile overlay */}
      {sidebarOpen && (
        <div onClick={()=>setSidebarOpen(false)} style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.6)',zIndex:40}}/>
      )}

      {/* ── SIDEBAR ── */}
      <div style={{
        width:220,flexShrink:0,background:'#001628',borderRight:'1px solid #002D55',
        display:'flex',flexDirection:'column',position:'fixed',top:0,bottom:0,left:0,zIndex:50,
        transform: sidebarOpen ? 'translateX(0)' : 'translateX(-100%)',
        transition:'transform 0.3s ease',
      }}
      className="admin-sidebar">
        <style>{`.admin-sidebar{transform:translateX(-100%)} @media(min-width:768px){.admin-sidebar{transform:translateX(0) !important}}`}</style>

        {/* Logo */}
        <div style={{padding:'20px 16px',borderBottom:'1px solid #002D55'}}>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF,#FFFFFF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}}>
            ProveRank
          </div>
          <div style={{fontSize:10,color:'#6B8FAF',letterSpacing:2,marginTop:2}}>ADMIN PANEL</div>
        </div>

        {/* Nav */}
        <nav style={{flex:1,padding:'12px 0',overflowY:'auto'}}>
          {NAV.map(item => {
            const isActive = pathname === item.href;
            return (
              <div key={item.href} onClick={()=>{router.push(item.href);setSidebarOpen(false);}}
                style={{display:'flex',alignItems:'center',gap:10,padding:'11px 16px',cursor:'pointer',
                  background:isActive?'rgba(77,159,255,0.12)':'transparent',
                  borderLeft:isActive?'3px solid #4D9FFF':'3px solid transparent',
                  transition:'all 0.2s',marginBottom:2}}>
                <span style={{fontSize:16}}>{item.icon}</span>
                <span style={{fontSize:13,fontWeight:isActive?600:400,color:isActive?'#4D9FFF':'#94A3B8'}}>{item.label}</span>
              </div>
            );
          })}
        </nav>

        {/* Bottom */}
        <div style={{padding:'12px 16px',borderTop:'1px solid #002D55'}}>
          <div onClick={()=>{logout();router.push('/login');}}
            style={{display:'flex',alignItems:'center',gap:8,padding:'10px 12px',borderRadius:8,cursor:'pointer',background:'rgba(239,68,68,0.08)',border:'1px solid rgba(239,68,68,0.2)'}}>
            <span>🚪</span>
            <span style={{fontSize:13,color:'#EF4444',fontWeight:500}}>Logout</span>
          </div>
        </div>
      </div>

      {/* ── MAIN CONTENT ── */}
      <div style={{flex:1,marginLeft:0,display:'flex',flexDirection:'column',minHeight:'100vh'}}
        className="admin-main">
        <style>{`@media(min-width:768px){.admin-main{margin-left:220px !important}}`}</style>

        {/* Top bar */}
        <div style={{background:'#001628',borderBottom:'1px solid #002D55',padding:'12px 16px',display:'flex',alignItems:'center',gap:12,position:'sticky',top:0,zIndex:30}}>
          <button onClick={()=>setSidebarOpen(!sidebarOpen)}
            style={{background:'rgba(77,159,255,0.1)',border:'1px solid #002D55',borderRadius:8,color:'#4D9FFF',padding:'6px 10px',cursor:'pointer',fontSize:16,fontFamily:'Inter,sans-serif'}}
            className="mobile-menu-btn">
            ☰
          </button>
          <style>{`@media(min-width:768px){.mobile-menu-btn{display:none !important}}`}</style>
          <div style={{flex:1}}/>
          <div style={{fontSize:12,color:'#6B8FAF',background:'rgba(0,22,40,0.8)',padding:'6px 12px',borderRadius:8,border:'1px solid #002D55'}}>
            👤 Admin
          </div>
        </div>

        {/* Page content */}
        <div style={{flex:1,overflow:'auto'}}>
          {children}
        </div>
      </div>
    </div>
  );
}
