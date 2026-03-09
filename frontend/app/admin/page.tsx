'use client';
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { getToken } from '@/lib/auth';

const MOCK_STATS = {
  totalStudents: 1250, newToday: 23,
  totalExams: 18, activeExams: 3,
  totalAttempts: 4820, todayAttempts: 142,
  avgScore: 487, topScore: 698,
  recentActivity: [
    { type:'exam', msg:'NEET Mock Series 6 created', time:'2 min ago' },
    { type:'student', msg:'New student registered: Rahul K.', time:'5 min ago' },
    { type:'result', msg:'150 students completed Mock 5', time:'1 hr ago' },
    { type:'exam', msg:'Mock Series 5 exam ended', time:'3 hr ago' },
    { type:'student', msg:'12 new registrations today', time:'5 hr ago' },
  ],
  upcomingExams: [
    { title:'NEET Mock Series 6', date:'2025-01-20', registered:89, status:'upcoming' },
    { title:'NEET Mock Series 7', date:'2025-01-27', registered:42, status:'draft' },
  ],
};

export default function AdminDashboard() {
  const router = useRouter();
  const [stats, setStats] = useState<typeof MOCK_STATS | null>(null);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    const fetchStats = async () => {
      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/admin/stats`, {
          headers: { Authorization: `Bearer ${getToken()}` }
        });
        if (res.ok) setStats(await res.json());
        else setStats(MOCK_STATS);
      } catch { setStats(MOCK_STATS); }
    };
    fetchStats();
  }, []);

  if (!mounted || !stats) return <div style={{padding:24,color:'#4D9FFF'}}>⟳ Loading...</div>;

  const statCards = [
    { l:'Total Students', v:stats.totalStudents, sub:`+${stats.newToday} today`, c:'#4D9FFF', icon:'👥', href:'/admin/students' },
    { l:'Total Exams', v:stats.totalExams, sub:`${stats.activeExams} active`, c:'#22C55E', icon:'📝', href:'/admin/exams' },
    { l:'Total Attempts', v:stats.totalAttempts, sub:`${stats.todayAttempts} today`, c:'#F59E0B', icon:'📊', href:'/admin/results' },
    { l:'Avg Score', v:stats.avgScore, sub:`Best: ${stats.topScore}`, c:'#A78BFA', icon:'🏆', href:'/admin/results' },
  ];

  return (
    <div style={{padding:'20px 16px',color:'#E8F4FF'}}>
      <style>{`@keyframes fadeUp{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:translateY(0)}}`}</style>

      <div style={{marginBottom:20}}>
        <h1 style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:'#E8F4FF',margin:'0 0 4px'}}>Admin Dashboard</h1>
        <p style={{fontSize:13,color:'#6B8FAF',margin:0}}>ProveRank platform overview</p>
      </div>

      {/* Stat Cards */}
      <div style={{display:'grid',gridTemplateColumns:'repeat(2,1fr)',gap:12,marginBottom:20}}>
        {statCards.map(({l,v,sub,c,icon,href},i)=>(
          <div key={l} onClick={()=>router.push(href)}
            style={{background:'#001628',border:`1px solid ${c}33`,borderRadius:14,padding:'16px',cursor:'pointer',animation:`fadeUp ${0.2+i*0.08}s ease`,transition:'border 0.2s'}}>
            <div style={{fontSize:22,marginBottom:8}}>{icon}</div>
            <div style={{fontSize:22,fontWeight:700,color:c,fontFamily:'Playfair Display,serif'}}>{v.toLocaleString()}</div>
            <div style={{fontSize:12,color:'#E8F4FF',fontWeight:600,marginTop:2}}>{l}</div>
            <div style={{fontSize:11,color:'#6B8FAF',marginTop:2}}>{sub}</div>
          </div>
        ))}
      </div>

      {/* Upcoming Exams */}
      <div style={{background:'#001628',border:'1px solid #002D55',borderRadius:16,padding:'16px',marginBottom:16}}>
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:14}}>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:15,fontWeight:700,color:'#E8F4FF'}}>📝 Upcoming Exams</div>
          <button onClick={()=>router.push('/admin/exams')} style={{background:'rgba(77,159,255,0.1)',border:'1px solid #002D55',borderRadius:8,color:'#4D9FFF',padding:'5px 10px',cursor:'pointer',fontSize:11,fontFamily:'Inter,sans-serif'}}>View All</button>
        </div>
        {stats.upcomingExams.map(exam=>(
          <div key={exam.title} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'10px 0',borderBottom:'1px solid #002D55'}}>
            <div>
              <div style={{fontSize:13,color:'#E8F4FF',fontWeight:500}}>{exam.title}</div>
              <div style={{fontSize:11,color:'#6B8FAF'}}>{exam.date} · {exam.registered} registered</div>
            </div>
            <span style={{fontSize:10,padding:'3px 8px',borderRadius:6,background:exam.status==='upcoming'?'rgba(34,197,94,0.15)':'rgba(107,114,128,0.15)',color:exam.status==='upcoming'?'#22C55E':'#6B7280',fontWeight:600}}>
              {exam.status.toUpperCase()}
            </span>
          </div>
        ))}
      </div>

      {/* Recent Activity */}
      <div style={{background:'#001628',border:'1px solid #002D55',borderRadius:16,padding:'16px'}}>
        <div style={{fontFamily:'Playfair Display,serif',fontSize:15,fontWeight:700,color:'#E8F4FF',marginBottom:14}}>🕐 Recent Activity</div>
        {stats.recentActivity.map((a,i)=>(
          <div key={i} style={{display:'flex',gap:10,padding:'8px 0',borderBottom:i<stats.recentActivity.length-1?'1px solid #002D55':'none'}}>
            <span style={{fontSize:16,flexShrink:0}}>{a.type==='exam'?'📝':a.type==='student'?'👤':'📊'}</span>
            <div style={{flex:1}}>
              <div style={{fontSize:12,color:'#E8F4FF'}}>{a.msg}</div>
              <div style={{fontSize:10,color:'#6B8FAF',marginTop:1}}>{a.time}</div>
            </div>
          </div>
        ))}
      </div>

      {/* Quick Actions */}
      <div style={{display:'grid',gridTemplateColumns:'repeat(2,1fr)',gap:10,marginTop:16}}>
        {[
          {l:'+ Create Exam',href:'/admin/exams',c:'#4D9FFF'},
          {l:'📢 Announce',href:'/admin/announcements',c:'#F59E0B'},
          {l:'👥 Students',href:'/admin/students',c:'#22C55E'},
          {l:'📊 Analytics',href:'/admin/results',c:'#A78BFA'},
        ].map(({l,href,c})=>(
          <button key={l} onClick={()=>router.push(href)}
            style={{padding:'12px',background:`${c}15`,border:`1px solid ${c}44`,borderRadius:10,color:c,fontSize:13,fontWeight:600,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>
            {l}
          </button>
        ))}
      </div>
    </div>
  );
}
