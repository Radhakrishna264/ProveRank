'use client';
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { getToken } from '@/lib/auth';

const MOCK_LEADERS = [
  { rank:1, name:'Arjun Sharma', score:698, percentile:99.8, correct:174, avatar:'🥇' },
  { rank:2, name:'Priya Singh', score:685, percentile:99.5, correct:171, avatar:'🥈' },
  { rank:3, name:'Rahul Verma', score:672, percentile:99.1, correct:168, avatar:'🥉' },
  { rank:4, name:'Sneha Patel', score:658, percentile:98.7, correct:164, avatar:'⭐' },
  { rank:5, name:'Amit Kumar', score:645, percentile:98.2, correct:161, avatar:'⭐' },
  { rank:42, name:'You', score:540, percentile:96.6, correct:135, avatar:'👤', isYou:true },
];

export default function LeaderboardPage() {
  const router = useRouter();
  const [leaders, setLeaders] = useState<(typeof MOCK_LEADERS[0] & { isYou?: boolean })[]>([]);
  const [loading, setLoading] = useState(true);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    if (!getToken()) { router.push('/login'); return; }
    const fetchLeaders = async () => {
      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/leaderboard`, {
          headers: { Authorization: `Bearer ${getToken()}` }
        });
        if (res.ok) { const data = await res.json(); setLeaders(data); }
        else setLeaders(MOCK_LEADERS);
      } catch { setLeaders(MOCK_LEADERS); }
      finally { setLoading(false); }
    };
    fetchLeaders();
  }, [router]);

  if (!mounted || loading) return <div style={{minHeight:'100vh',background:'#000A18',display:'flex',alignItems:'center',justifyContent:'center',color:'#4D9FFF',fontSize:16}}>⟳ Loading...</div>;

  return (
    <div style={{minHeight:'100vh',background:'#000A18',fontFamily:'Inter,sans-serif',color:'#E8F4FF'}}>
      <style>{`@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600&display=swap');@keyframes fadeUp{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:translateY(0)}}`}</style>

      {/* Header */}
      <div style={{background:'#001628',borderBottom:'1px solid #002D55',padding:'14px 16px',display:'flex',alignItems:'center',gap:12,position:'sticky',top:0,zIndex:50}}>
        <button onClick={()=>router.push('/dashboard')} style={{background:'rgba(77,159,255,0.1)',border:'1px solid #002D55',borderRadius:8,color:'#4D9FFF',padding:'6px 12px',cursor:'pointer',fontSize:13,fontFamily:'Inter,sans-serif'}}>← Back</button>
        <div style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:'#E8F4FF'}}>🏆 Leaderboard</div>
      </div>

      <div style={{padding:'16px'}}>
        {/* Top 3 Podium */}
        <div style={{display:'flex',alignItems:'flex-end',justifyContent:'center',gap:8,marginBottom:24,animation:'fadeUp 0.4s ease'}}>
          {[leaders[1],leaders[0],leaders[2]].filter(Boolean).map((l,i)=>{
            const heights = [100,130,85];
            const colors = ['#94A3B8','#F59E0B','#CD7C32'];
            return (
              <div key={l.rank} style={{textAlign:'center',flex:1}}>
                <div style={{fontSize:28,marginBottom:4}}>{l.avatar}</div>
                <div style={{fontSize:11,color:'#E8F4FF',fontWeight:600,marginBottom:4}}>{l.name.split(' ')[0]}</div>
                <div style={{fontSize:13,color:'#4D9FFF',fontWeight:700}}>{l.score}</div>
                <div style={{height:heights[i],background:`linear-gradient(180deg,${colors[i]}33,${colors[i]}11)`,border:`1px solid ${colors[i]}44`,borderRadius:'8px 8px 0 0',marginTop:8,display:'flex',alignItems:'center',justifyContent:'center'}}>
                  <span style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:700,color:colors[i]}}>#{[2,1,3][i]}</span>
                </div>
              </div>
            );
          })}
        </div>

        {/* Full List */}
        <div style={{display:'flex',flexDirection:'column',gap:8}}>
          {leaders.map((l, i) => (
            <div key={l.rank} style={{background: l.isYou ? 'rgba(77,159,255,0.1)' : '#001628',border:`1px solid ${l.isYou?'#4D9FFF':'#002D55'}`,borderRadius:12,padding:'14px 16px',display:'flex',alignItems:'center',gap:12,animation:`fadeUp ${0.3+i*0.05}s ease`}}>
              <div style={{width:32,textAlign:'center',fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:l.rank<=3?'#F59E0B':l.isYou?'#4D9FFF':'#6B8FAF',flexShrink:0}}>
                #{l.rank}
              </div>
              <div style={{fontSize:22,flexShrink:0}}>{l.avatar}</div>
              <div style={{flex:1}}>
                <div style={{fontSize:13,fontWeight:600,color:l.isYou?'#4D9FFF':'#E8F4FF'}}>{l.name} {l.isYou&&<span style={{fontSize:10,background:'#4D9FFF',color:'white',padding:'1px 6px',borderRadius:4,marginLeft:4}}>YOU</span>}</div>
                <div style={{fontSize:11,color:'#6B8FAF'}}>✅ {l.correct}/180 · {l.percentile}%ile</div>
              </div>
              <div style={{textAlign:'right'}}>
                <div style={{fontSize:18,fontWeight:700,color:'#E8F4FF',fontFamily:'Playfair Display,serif'}}>{l.score}</div>
                <div style={{fontSize:10,color:'#6B8FAF'}}>/ 720</div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
