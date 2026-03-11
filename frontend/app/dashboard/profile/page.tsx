'use client';
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { getToken } from '../../../lib/auth';

export default function ProfilePage() {
  const router = useRouter();
  const [student, setStudent] = useState<any>(null);
  const [attempts, setAttempts] = useState<any[]>([]);
  const [mounted, setMounted] = useState(false);
  const API = process.env.NEXT_PUBLIC_API_URL;

  useEffect(() => {
    setMounted(true);
    const token = getToken();
    if (!token) { router.push('/login'); return; }
    Promise.all([
      fetch(`${API}/api/auth/me`, { headers: { Authorization: `Bearer ${token}` } }).then(r=>r.json()),
      fetch(`${API}/api/results/my`, { headers: { Authorization: `Bearer ${token}` } }).then(r=>r.json()),
    ]).then(([me, res]) => {
      setStudent(me);
      setAttempts(res.results || res || []);
    }).catch(()=>{});
  }, []);

  if (!mounted) return null;

  const bestRank = attempts.length ? Math.min(...attempts.map((a:any)=>a.rank||999)) : null;
  const avgScore = attempts.length ? Math.round(attempts.reduce((s:number,a:any)=>s+(a.score||0),0)/attempts.length) : 0;
  const bestScore = attempts.length ? Math.max(...attempts.map((a:any)=>a.score||0)) : 0;

  const badges = [
    {icon:'🥇',label:'First Attempt',earned:attempts.length>=1},
    {icon:'🔥',label:'5 Exams Done',earned:attempts.length>=5},
    {icon:'⭐',label:'Score 500+',earned:bestScore>=500},
    {icon:'🏆',label:'Top 10 Rank',earned:bestRank!==null&&bestRank<=10},
    {icon:'💎',label:'Score 600+',earned:bestScore>=600},
    {icon:'🎯',label:'10 Exams Done',earned:attempts.length>=10},
  ];

  return (
    <div style={{minHeight:'100vh',background:'#000A18',fontFamily:'Inter,sans-serif'}}>
      <style>{`@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;600&display=swap');*{box-sizing:border-box;margin:0;padding:0}`}</style>
      <div style={{display:'flex',minHeight:'100vh'}}>
        {/* Sidebar */}
        <div style={{width:'220px',background:'#001628',borderRight:'1px solid #002D55',padding:'24px 0',display:'flex',flexDirection:'column',position:'fixed',height:'100vh',zIndex:10}}>
          <div style={{padding:'0 20px 24px',borderBottom:'1px solid #002D55'}}>
            <div style={{display:'flex',alignItems:'center',gap:'8px'}}>
              <svg width="28" height="28" viewBox="0 0 40 46"><polygon points="20,2 38,12 38,34 20,44 2,34 2,12" fill="none" stroke="#4D9FFF" strokeWidth="2.5"/><text x="50%" y="55%" dominantBaseline="middle" textAnchor="middle" fill="#4D9FFF" fontSize="13" fontWeight="bold" fontFamily="Inter">PR</text></svg>
              <div><div style={{fontFamily:'Playfair Display,serif',fontSize:'18px',fontWeight:700,color:'#E8F4FF'}}>ProveRank</div><div style={{fontSize:'10px',color:'#6B8BAF'}}>Student Portal</div></div>
            </div>
          </div>
          {[{l:'🏠 Dashboard',h:'/dashboard'},{l:'📝 Exams',h:'/dashboard/exams'},{l:'📊 Results',h:'/dashboard/results/history'},{l:'🏆 Leaderboard',h:'/dashboard/leaderboard'},{l:'👤 Profile',h:'/dashboard/profile',a:true}].map(({l,h,a})=>(
            <button key={l} onClick={()=>router.push(h)} style={{display:'block',width:'100%',textAlign:'left',padding:'12px 20px',background:a?'rgba(77,159,255,0.1)':'transparent',borderLeft:a?'3px solid #4D9FFF':'3px solid transparent',border:'none',color:a?'#E8F4FF':'#6B8BAF',fontSize:'13px',cursor:'pointer',fontFamily:'Inter,sans-serif'}}>{l}</button>
          ))}
          <div style={{marginTop:'auto',padding:'20px'}}>
            <button onClick={()=>{localStorage.clear();window.location.href='/login';}} style={{width:'100%',padding:'10px',background:'rgba(255,60,60,0.1)',border:'1px solid rgba(255,60,60,0.3)',borderRadius:'8px',color:'#ff6b6b',fontSize:'13px',cursor:'pointer'}}>🚪 Logout</button>
          </div>
        </div>
        {/* Content */}
        <div style={{marginLeft:'220px',flex:1,padding:'32px'}}>
          {/* Cover + Avatar — P2 */}
          <div style={{background:'linear-gradient(135deg,#001628,#002D55)',borderRadius:'16px',padding:'0',marginBottom:'80px',position:'relative',overflow:'visible',border:'1px solid #002D55'}}>
            <div style={{height:'140px',background:'linear-gradient(135deg,#001628 0%,#003875 50%,#001628 100%)',borderRadius:'16px 16px 0 0',display:'flex',alignItems:'center',justifyContent:'center'}}>
              <div style={{fontSize:'40px',opacity:0.15}}>⬡ ⬡ ⬡ ⬡ ⬡</div>
            </div>
            <div style={{position:'absolute',bottom:'-50px',left:'32px',width:'90px',height:'90px',borderRadius:'50%',background:'linear-gradient(135deg,#002D55,#004080)',border:'4px solid #000A18',display:'flex',alignItems:'center',justifyContent:'center',fontSize:'36px'}}>
              {student?.name?.[0]||'S'}
            </div>
          </div>
          <div style={{marginBottom:'28px'}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:'24px',fontWeight:700,color:'#E8F4FF'}}>{student?.name||'Student'}</div>
            <div style={{fontSize:'13px',color:'#6B8BAF',marginTop:'4px'}}>{student?.email||''} · Student</div>
          </div>

          {/* Stats */}
          <div style={{display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:'16px',marginBottom:'28px'}}>
            {[{l:'Total Exams',v:attempts.length,c:'#4D9FFF'},{l:'Best Rank',v:bestRank?`#${bestRank}`:'-',c:'#F59E0B'},{l:'Best Score',v:`${bestScore}/720`,c:'#22C55E'}].map(({l,v,c})=>(
              <div key={l} style={{background:'#001628',border:'1px solid #002D55',borderRadius:'12px',padding:'20px',textAlign:'center'}}>
                <div style={{fontFamily:'Playfair Display,serif',fontSize:'24px',fontWeight:700,color:c}}>{v}</div>
                <div style={{fontSize:'11px',color:'#6B8BAF',marginTop:'4px'}}>{l}</div>
              </div>
            ))}
          </div>

          {/* Badge Room — B3 Trophy Room */}
          <div style={{background:'#001628',border:'1px solid #002D55',borderRadius:'14px',padding:'24px',marginBottom:'20px'}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:'16px',fontWeight:700,color:'#E8F4FF',marginBottom:'16px'}}>🏅 Achievement Badges</div>
            <div style={{display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:'12px'}}>
              {badges.map(b=>(
                <div key={b.label} style={{background:b.earned?'rgba(77,159,255,0.1)':'#000A18',border:`1px solid ${b.earned?'rgba(77,159,255,0.3)':'#002D55'}`,borderRadius:'10px',padding:'16px',textAlign:'center',opacity:b.earned?1:0.4}}>
                  <div style={{fontSize:'28px',marginBottom:'8px'}}>{b.icon}</div>
                  <div style={{fontSize:'11px',color:b.earned?'#E8F4FF':'#6B8BAF',fontWeight:600}}>{b.label}</div>
                  {!b.earned&&<div style={{fontSize:'10px',color:'#6B8BAF',marginTop:'4px'}}>🔒 Locked</div>}
                </div>
              ))}
            </div>
          </div>

          {/* Avg Score */}
          <div style={{background:'#001628',border:'1px solid #002D55',borderRadius:'14px',padding:'24px'}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:'16px',fontWeight:700,color:'#E8F4FF',marginBottom:'16px'}}>📊 Performance Summary</div>
            <div style={{display:'flex',justifyContent:'space-between',padding:'12px 0',borderBottom:'1px solid #002D55'}}>
              <span style={{color:'#6B8BAF',fontSize:'13px'}}>Average Score</span>
              <span style={{color:'#4D9FFF',fontWeight:600}}>{avgScore} / 720</span>
            </div>
            <div style={{display:'flex',justifyContent:'space-between',padding:'12px 0',borderBottom:'1px solid #002D55'}}>
              <span style={{color:'#6B8BAF',fontSize:'13px'}}>Total Attempts</span>
              <span style={{color:'#E8F4FF',fontWeight:600}}>{attempts.length}</span>
            </div>
            <div style={{display:'flex',justifyContent:'space-between',padding:'12px 0'}}>
              <span style={{color:'#6B8BAF',fontSize:'13px'}}>Best Rank</span>
              <span style={{color:'#F59E0B',fontWeight:600}}>{bestRank ? `#${bestRank}` : 'N/A'}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
