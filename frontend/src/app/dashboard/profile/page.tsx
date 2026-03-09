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
