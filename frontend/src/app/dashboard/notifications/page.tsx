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
