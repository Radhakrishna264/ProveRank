'use client';
import { useEffect, useState } from 'react';
import { getToken } from '@/lib/auth';

const PRI: Record<string,{color:string;bg:string;icon:string;label:string}> = {
  low:    { color:'#4D9FFF', bg:'rgba(77,159,255,0.08)',  icon:'ℹ️', label:'Info'      },
  medium: { color:'#FFD700', bg:'rgba(255,215,0,0.08)',   icon:'📌', label:'Notice'    },
  high:   { color:'#FF9F4D', bg:'rgba(255,159,77,0.08)',  icon:'⚠️', label:'Important' },
  urgent: { color:'#FF4D4D', bg:'rgba(255,77,77,0.08)',   icon:'🚨', label:'URGENT'    },
};

export default function NoticesPage() {
  const [notices, setNotices] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [expanded, setExpanded] = useState<string|null>(null);

  useEffect(() => {
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/admin/notices`, { headers:{ Authorization:`Bearer ${getToken()}` } })
      .then(r => r.json())
      .then(d => { setNotices(Array.isArray(d) ? d : d.notices || []); setLoading(false); })
      .catch(() => setLoading(false));
  }, []);

  return (
    <div style={{ maxWidth:800, margin:'0 auto' }}>
      <div style={{ fontFamily:'Playfair Display,serif', fontSize:22, color:'var(--text)', marginBottom:4 }}>📋 Notice Board</div>
      <div style={{ color:'var(--muted)', fontSize:13, marginBottom:24 }}>Admin ke saare notices yahan milenge</div>
      {loading ? <div style={{ textAlign:'center', color:'var(--muted)', padding:60 }}>Loading...</div>
       : notices.length === 0
        ? <div style={{ textAlign:'center', background:'var(--card)', border:'1px solid var(--border)', borderRadius:14, padding:60 }}>
            <div style={{ fontSize:48, marginBottom:12 }}>📭</div>
            <div style={{ color:'var(--muted)', fontSize:14 }}>Koi notice nahi abhi</div>
          </div>
        : <div style={{ display:'flex', flexDirection:'column', gap:12 }}>
            {notices.map(n => {
              const cfg = PRI[n.priority] || PRI.medium;
              const isExp = expanded === n._id;
              return (
                <div key={n._id} onClick={() => setExpanded(isExp ? null : n._id)} style={{ background:cfg.bg, border:`1px solid ${cfg.color}44`, borderLeft:`4px solid ${cfg.color}`, borderRadius:12, padding:'16px 20px', cursor:'pointer' }}>
                  <div style={{ display:'flex', justifyContent:'space-between', alignItems:'flex-start' }}>
                    <div style={{ display:'flex', gap:10, flex:1 }}>
                      <span style={{ fontSize:20, flexShrink:0 }}>{cfg.icon}</span>
                      <div style={{ flex:1 }}>
                        <div style={{ display:'flex', gap:8, alignItems:'center', marginBottom:4 }}>
                          <span style={{ fontSize:11, color:cfg.color, fontWeight:700, textTransform:'uppercase', letterSpacing:0.5 }}>{cfg.label}</span>
                        </div>
                        <div style={{ fontSize:15, fontWeight:700, color:'var(--text)' }}>{n.title}</div>
                        {isExp
                          ? <div style={{ fontSize:13, color:'var(--muted)', marginTop:10, lineHeight:1.7, whiteSpace:'pre-wrap' }}>{n.message}</div>
                          : <div style={{ fontSize:12, color:'var(--muted)', marginTop:6 }}>{(n.message||'').slice(0,100)}{(n.message||'').length>100?'... ':''}
                              {(n.message||'').length>100 && <span style={{ color:cfg.color }}>Read more</span>}
                            </div>
                        }
                      </div>
                    </div>
                    <div style={{ textAlign:'right', flexShrink:0, marginLeft:12 }}>
                      <div style={{ fontSize:11, color:'var(--muted)' }}>{new Date(n.createdAt).toLocaleDateString('en-IN')}</div>
                      <div style={{ fontSize:12, color:cfg.color, marginTop:4 }}>{isExp ? '▲' : '▼'}</div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
      }
    </div>
  );
}
