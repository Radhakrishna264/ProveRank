'use client';
import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { getToken, getRole } from '../../lib/auth';

export default function StudentDashboard() {
  const router = useRouter();
  const [student, setStudent] = useState<any>(null);
  const [exams, setExams] = useState<any[]>([]);
  const [attempts, setAttempts] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const API = process.env.NEXT_PUBLIC_API_URL;

  useEffect(() => {
    const token = getToken();
    const role = getRole();
    if (!token || role !== 'student') {
      window.location.href = '/login';
      return;
    }
    fetchData(token);
  }, []);

  async function fetchData(token: string) {
    try {
      const [meRes, examsRes, attemptsRes] = await Promise.all([
        fetch(`${API}/api/auth/me`, { headers: { Authorization: `Bearer ${token}` } }),
        fetch(`${API}/api/exams`, { headers: { Authorization: `Bearer ${token}` } }),
        fetch(`${API}/api/results/my`, { headers: { Authorization: `Bearer ${token}` } }),
      ]);
      if (meRes.ok) { const d = await meRes.json(); setStudent(d); }
      if (examsRes.ok) { const d = await examsRes.json(); setExams(d.exams || d || []); }
      if (attemptsRes.ok) { const d = await attemptsRes.json(); setAttempts(d.results || d || []); }
    } catch(e) { console.error(e); }
    setLoading(false);
  }

  const bestRank = attempts.length ? Math.min(...attempts.map((a:any) => a.rank || 999)) : null;
  const avgScore = attempts.length ? Math.round(attempts.reduce((s:number,a:any) => s + (a.score||0), 0) / attempts.length) : 0;
  const upcomingExams = exams.filter((e:any) => e.status === 'upcoming' || new Date(e.startTime) > new Date());

  if (loading) return (
    <div style={{minHeight:'100vh',display:'flex',alignItems:'center',justifyContent:'center',
      background:'#000A18',color:'#E8F4FF',fontFamily:'Inter,sans-serif',fontSize:'18px'}}>
      <style>{`@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;600&display=swap')`}</style>
      Loading...
    </div>
  );

  return (
    <div style={{minHeight:'100vh',background:'#000A18',fontFamily:'Inter,sans-serif'}}>
      <style>{`@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;600&display=swap');*{box-sizing:border-box;margin:0;padding:0}::-webkit-scrollbar{width:6px}::-webkit-scrollbar-track{background:#001628}::-webkit-scrollbar-thumb{background:#002D55;border-radius:3px}`}</style>

      {/* Sidebar + Main Layout */}
      <div style={{display:'flex',minHeight:'100vh'}}>

        {/* Sidebar */}
        <div style={{width:'220px',background:'#001628',borderRight:'1px solid #002D55',
          padding:'24px 0',display:'flex',flexDirection:'column',position:'fixed',height:'100vh',zIndex:10}}>
          <div style={{padding:'0 20px 24px',borderBottom:'1px solid #002D55'}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:'22px',
              fontWeight:700,color:'#E8F4FF'}}>⬡ ProveRank</div>
            <div style={{fontSize:'11px',color:'#6B8BAF',marginTop:'2px'}}>Student Portal</div>
          </div>
          {[
            {l:'🏠 Dashboard',h:'/dashboard',a:true},
            {l:'📝 Exams',h:'/dashboard/exams'},
            {l:'📊 Results',h:'/dashboard/results/history'},
            {l:'🏆 Leaderboard',h:'/dashboard/leaderboard'},
            {l:'👤 Profile',h:'/dashboard/profile'},
          ].map(({l,h,a})=>(
            <button key={l} onClick={()=>router.push(h)}
              style={{display:'block',width:'100%',textAlign:'left',padding:'12px 20px',
                background:a?'rgba(77,159,255,0.1)':'transparent',
                borderLeft:a?'3px solid #4D9FFF':'3px solid transparent',
                border:'none',color:a?'#E8F4FF':'#6B8BAF',fontSize:'13px',
                cursor:'pointer',fontFamily:'Inter,sans-serif',
                transition:'all 0.2s'}}>
              {l}
            </button>
          ))}
          <div style={{marginTop:'auto',padding:'20px'}}>
            <button onClick={()=>{localStorage.clear();window.location.href='/login';}}
              style={{width:'100%',padding:'10px',background:'rgba(255,60,60,0.1)',
                border:'1px solid rgba(255,60,60,0.3)',borderRadius:'8px',
                color:'#ff6b6b',fontSize:'13px',cursor:'pointer',fontFamily:'Inter,sans-serif'}}>
              🚪 Logout
            </button>
          </div>
        </div>

        {/* Main Content */}
        <div style={{marginLeft:'220px',flex:1,padding:'32px'}}>

          {/* Header */}
          <div style={{marginBottom:'28px'}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:'26px',
              fontWeight:700,color:'#E8F4FF'}}>
              Welcome back, {student?.name || 'Student'} 👋
            </div>
            <div style={{fontSize:'13px',color:'#6B8BAF',marginTop:'4px'}}>
              {new Date().toLocaleDateString('en-IN',{weekday:'long',year:'numeric',month:'long',day:'numeric'})}
            </div>
          </div>

          {/* Stats Cards */}
          <div style={{display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:'16px',marginBottom:'24px'}}>
            {[
              {l:'Total Attempts',v:attempts.length,sub:'exams given',c:'#4D9FFF'},
              {l:'Best Rank',v:bestRank ? `#${bestRank}` : '-',sub:'all time',c:'#F59E0B'},
              {l:'Avg Score',v:`${avgScore}`,sub:'/ 720',c:'#22C55E'},
            ].map(({l,v,sub,c})=>(
              <div key={l} style={{background:'#001628',border:'1px solid #002D55',
                borderRadius:'12px',padding:'20px',animation:'fadeUp 0.4s ease'}}>
                <div style={{fontSize:'12px',color:'#6B8BAF',marginBottom:'8px'}}>{l}</div>
                <div style={{fontSize:'28px',fontWeight:700,color:c,
                  fontFamily:'Playfair Display,serif'}}>{v}</div>
                <div style={{fontSize:'11px',color:'#6B8BAF',marginTop:'4px'}}>{sub}</div>
              </div>
            ))}
          </div>

          {/* Upcoming Exams */}
          <div style={{background:'#001628',border:'1px solid #002D55',
            borderRadius:'12px',padding:'20px',marginBottom:'20px'}}>
            <div style={{display:'flex',justifyContent:'space-between',
              alignItems:'center',marginBottom:'16px'}}>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:'16px',
                fontWeight:700,color:'#E8F4FF'}}>📅 Upcoming Exams</div>
              <button onClick={()=>router.push('/dashboard/exams')}
                style={{padding:'6px 14px',background:'rgba(77,159,255,0.1)',
                  border:'1px solid rgba(77,159,255,0.3)',borderRadius:'8px',
                  color:'#4D9FFF',fontSize:'12px',cursor:'pointer',fontFamily:'Inter,sans-serif'}}>
                View All
              </button>
            </div>
            {upcomingExams.length === 0 ? (
              <div style={{textAlign:'center',color:'#6B8BAF',padding:'20px',fontSize:'14px'}}>
                No upcoming exams
              </div>
            ) : upcomingExams.slice(0,3).map((exam:any)=>(
              <div key={exam._id} style={{display:'flex',justifyContent:'space-between',
                alignItems:'center',padding:'12px 0',borderBottom:'1px solid #002D55'}}>
                <div>
                  <div style={{fontSize:'14px',fontWeight:600,color:'#E8F4FF'}}>{exam.title}</div>
                  <div style={{fontSize:'11px',color:'#6B8BAF',marginTop:'2px'}}>
                    {new Date(exam.startTime).toLocaleString('en-IN')}
                  </div>
                </div>
                <button onClick={()=>router.push(`/exam/${exam._id}`)}
                  style={{padding:'6px 14px',background:'#4D9FFF',border:'none',
                    borderRadius:'8px',color:'#000',fontSize:'12px',cursor:'pointer',
                    fontWeight:600,fontFamily:'Inter,sans-serif'}}>
                  Start
                </button>
              </div>
            ))}
          </div>

          {/* Recent Results */}
          <div style={{background:'#001628',border:'1px solid #002D55',
            borderRadius:'12px',padding:'20px'}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:'16px',
              fontWeight:700,color:'#E8F4FF',marginBottom:'16px'}}>📊 Recent Results</div>
            {attempts.length === 0 ? (
              <div style={{textAlign:'center',color:'#6B8BAF',padding:'20px',fontSize:'14px'}}>
                No attempts yet — give your first exam!
              </div>
            ) : attempts.slice(0,5).map((a:any)=>(
              <div key={a._id||a.attemptId}
                onClick={()=>router.push(`/dashboard/results/${a.attemptId||a._id}`)}
                style={{display:'flex',justifyContent:'space-between',alignItems:'center',
                  padding:'12px',marginBottom:'8px',background:'#000A18',
                  borderRadius:'8px',cursor:'pointer',border:'1px solid #002D55',
                  transition:'border 0.2s'}}>
                <div>
                  <div style={{fontSize:'13px',fontWeight:600,color:'#E8F4FF'}}>{a.examTitle||'Exam'}</div>
                  <div style={{fontSize:'11px',color:'#6B8BAF',marginTop:'2px'}}>
                    {a.date||new Date(a.createdAt).toLocaleDateString('en-IN')}
                  </div>
                </div>
                <div style={{textAlign:'right'}}>
                  <div style={{fontSize:'18px',fontWeight:700,color:'#22C55E',
                    fontFamily:'Playfair Display,serif'}}>{a.score||0}</div>
                  <div style={{fontSize:'10px',color:'#6B8BAF'}}>Rank #{a.rank||'-'}</div>
                </div>
              </div>
            ))}
          </div>

        </div>
      </div>
      <style>{`@keyframes fadeUp{from{opacity:0;transform:translateY(10px)}to{opacity:1;transform:translateY(0)}}`}</style>
    </div>
  );
}
