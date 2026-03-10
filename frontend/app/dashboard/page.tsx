'use client';
import { useEffect, useState } from 'react';
import { getToken, getRole } from '../../lib/auth';

export default function DashboardPage() {
  const [ready, setReady] = useState(false);
  const [role, setRole] = useState('');

  useEffect(() => {
    const token = getToken();
    const r = getRole();
    if (!token) {
      window.location.href = '/login';
      return;
    }
    setRole(r || 'student');
    setReady(true);
  }, []);

  if (!ready) return (
    <div style={{minHeight:'100vh',display:'flex',alignItems:'center',
      justifyContent:'center',background:'#0a0f1e',color:'#4DFFF3',
      fontFamily:'Inter,sans-serif',fontSize:'18px'}}>
      Loading Dashboard...
    </div>
  );

  return (
    <div style={{minHeight:'100vh',background:'#0a0f1e',color:'#fff',
      fontFamily:'Inter,sans-serif',padding:'40px'}}>
      <h1 style={{color:'#4DFFF3',fontSize:'32px'}}>
        ⬡ ProveRank Dashboard
      </h1>
      <p style={{color:'#aaa',marginTop:'10px'}}>
        ✅ Login Successful! Role: <b style={{color:'#4DFFF3'}}>{role}</b>
      </p>
      <button onClick={() => {
        localStorage.clear();
        window.location.href = '/login';
      }} style={{marginTop:'30px',padding:'10px 24px',
        background:'#4DFFF3',color:'#0a0f1e',border:'none',
        borderRadius:'8px',cursor:'pointer',fontWeight:'bold'}}>
        Logout
      </button>
    </div>
  );
}
