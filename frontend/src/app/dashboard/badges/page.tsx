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
