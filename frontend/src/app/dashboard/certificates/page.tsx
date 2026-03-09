'use client';
import { useEffect, useRef, useState } from 'react';
import { getToken } from '@/lib/auth';

export default function CertificatesPage() {
  const [certs,   setCerts]   = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<any>(null);
  const printRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/results/certificates`, { headers:{ Authorization:`Bearer ${getToken()}` } })
      .then(r => r.json())
      .then(d => { setCerts(Array.isArray(d) ? d : d.certificates || []); setLoading(false); })
      .catch(() => setLoading(false));
  }, []);

  const handlePrint = () => {
    if (!printRef.current) return;
    const win = window.open('','_blank');
    if (!win) return;
    win.document.write(`<html><head><title>Certificate — ProveRank</title><style>@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;600&display=swap');body{margin:0;background:white;}</style></head><body>${printRef.current.innerHTML}</body></html>`);
    win.document.close(); setTimeout(() => win.print(), 500);
  };

  const shareWA = (c: any) => {
    const text = `🎓 Maine ProveRank pe "${c.examTitle}" mein Rank #${c.rank} hasil kiya! Score: ${c.score}/${c.maxScore} · Percentile: ${Number(c.percentile).toFixed(1)}% 🏆 #ProveRank #NEET`;
    window.open(`https://wa.me/?text=${encodeURIComponent(text)}`, '_blank');
  };

  return (
    <div style={{ maxWidth:900, margin:'0 auto' }}>
      <div style={{ fontFamily:'Playfair Display,serif', fontSize:22, color:'var(--text)', marginBottom:4 }}>🎓 My Certificates</div>
      <div style={{ color:'var(--muted)', fontSize:13, marginBottom:24 }}>Apne achievements ke certificates yahan dekho aur download karo</div>

      {loading ? <div style={{ textAlign:'center', color:'var(--muted)', padding:60 }}>Loading...</div>
       : certs.length === 0
        ? <div style={{ textAlign:'center', background:'var(--card)', border:'1px solid var(--border)', borderRadius:14, padding:60 }}>
            <div style={{ fontSize:48, marginBottom:12 }}>🎓</div>
            <div style={{ color:'var(--muted)', fontSize:14 }}>Abhi koi certificate nahi hai</div>
            <div style={{ color:'var(--muted)', fontSize:12, marginTop:8 }}>Exams complete karo certificates earn karne ke liye</div>
          </div>
        : <>
            <div style={{ display:'grid', gridTemplateColumns:'repeat(auto-fill,minmax(280px,1fr))', gap:16, marginBottom:32 }}>
              {certs.map(c => (
                <div key={c._id} onClick={() => setSelected(c)} style={{ background:'var(--card)', border:`1px solid ${selected?._id===c._id?'var(--primary)':'var(--border)'}`, borderRadius:14, padding:20, cursor:'pointer', transition:'all 0.2s' }}>
                  <div style={{ fontSize:32, marginBottom:12 }}>🎓</div>
                  <div style={{ fontSize:14, fontWeight:700, color:'var(--text)', marginBottom:8 }}>{c.examTitle}</div>
                  <div style={{ display:'flex', gap:12, marginBottom:12 }}>
                    {[{v:`#${c.rank}`,l:'Rank',color:'#FFD700'},{v:`${c.score}/${c.maxScore}`,l:'Score',color:'#4D9FFF'},{v:`${Number(c.percentile).toFixed(1)}%`,l:'Percentile',color:'#4DFF90'}].map(({v,l,color})=>(
                      <div key={l} style={{ textAlign:'center', flex:1 }}>
                        <div style={{ fontSize:16, fontWeight:700, color }}>{v}</div>
                        <div style={{ fontSize:10, color:'var(--muted)' }}>{l}</div>
                      </div>
                    ))}
                  </div>
                  <div style={{ display:'flex', gap:8 }}>
                    <button onClick={e => { e.stopPropagation(); setSelected(c); setTimeout(handlePrint,100); }} style={{ flex:1, background:'var(--primary)', color:'#000A18', border:'none', borderRadius:8, padding:8, cursor:'pointer', fontWeight:600, fontSize:12 }}>📥 Download</button>
                    <button onClick={e => { e.stopPropagation(); shareWA(c); }} style={{ flex:1, background:'rgba(37,211,102,0.1)', color:'#25D366', border:'1px solid rgba(37,211,102,0.3)', borderRadius:8, padding:8, cursor:'pointer', fontSize:12, fontWeight:600 }}>📱 Share</button>
                  </div>
                </div>
              ))}
            </div>

            {selected && (
              <div style={{ marginTop:16 }}>
                <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:16 }}>
                  <div style={{ fontFamily:'Playfair Display,serif', fontSize:16, color:'var(--text)' }}>🎓 Certificate Preview</div>
                  <div style={{ display:'flex', gap:8 }}>
                    <button onClick={handlePrint} style={{ background:'var(--primary)', color:'#000A18', border:'none', borderRadius:8, padding:'8px 18px', cursor:'pointer', fontWeight:600, fontSize:13 }}>📥 Download PDF</button>
                    <button onClick={() => shareWA(selected)} style={{ background:'rgba(37,211,102,0.1)', color:'#25D366', border:'1px solid rgba(37,211,102,0.3)', borderRadius:8, padding:'8px 18px', cursor:'pointer', fontSize:13, fontWeight:600 }}>📱 WhatsApp</button>
                  </div>
                </div>
                {/* CR1: Certificate with PR4 Hexagon Corners */}
                <div ref={printRef} style={{ background:'white', color:'#0a1628', padding:48, maxWidth:700, margin:'0 auto', borderRadius:4, border:'8px solid #1a6fd4', outline:'4px solid #c5d8f0', outlineOffset:-16, fontFamily:'Georgia,serif', position:'relative' }}>
                  {['top:8px;left:8px','top:8px;right:8px','bottom:8px;left:8px','bottom:8px;right:8px'].map((pos,i) => (
                    <div key={i} style={{ position:'absolute', fontSize:40, color:'#1a6fd4', opacity:0.15, ...(Object.fromEntries(pos.split(';').map(p => p.split(':')))) }}>⬡</div>
                  ))}
                  <div style={{ textAlign:'center', marginBottom:32 }}>
                    <div style={{ fontSize:36, color:'#1a6fd4', fontWeight:900, fontFamily:'Playfair Display,Georgia,serif', marginBottom:4 }}>⬡ ProveRank</div>
                    <div style={{ fontSize:11, color:'#4a6080', letterSpacing:4, textTransform:'uppercase' }}>NEET Pattern Online Test Platform</div>
                  </div>
                  <div style={{ textAlign:'center', marginBottom:32 }}>
                    <div style={{ fontSize:13, color:'#4a6080', letterSpacing:3, textTransform:'uppercase', marginBottom:8 }}>This is to certify that</div>
                    <div style={{ fontSize:32, color:'#0a1628', fontWeight:700, fontFamily:'Playfair Display,Georgia,serif', borderBottom:'2px solid #1a6fd4', paddingBottom:8, display:'inline-block', marginBottom:8 }}>{selected.studentName}</div>
                    <div style={{ fontSize:13, color:'#4a6080', letterSpacing:2, textTransform:'uppercase', marginTop:8 }}>has successfully completed</div>
                  </div>
                  <div style={{ textAlign:'center', background:'#e8f4ff', borderRadius:8, padding:'16px 24px', marginBottom:32 }}>
                    <div style={{ fontSize:20, fontWeight:700, color:'#0a1628', fontFamily:'Playfair Display,Georgia,serif' }}>{selected.examTitle}</div>
                    <div style={{ fontSize:13, color:'#4a6080', marginTop:4 }}>Held on {new Date(selected.examDate||Date.now()).toLocaleDateString('en-IN',{ day:'numeric',month:'long',year:'numeric' })}</div>
                  </div>
                  <div style={{ display:'flex', justifyContent:'space-around', marginBottom:32 }}>
                    {[{l:'Score',v:`${selected.score}/${selected.maxScore}`,c:'#1a6fd4'},{l:'Rank Achieved',v:`#${selected.rank}`,c:'#B8860B'},{l:'Percentile',v:`${Number(selected.percentile).toFixed(1)}%`,c:'#0a7040'}].map(({l,v,c})=>(
                      <div key={l} style={{ textAlign:'center' }}>
                        <div style={{ fontSize:28, fontWeight:700, color:c }}>{v}</div>
                        <div style={{ fontSize:11, color:'#4a6080', textTransform:'uppercase', letterSpacing:1 }}>{l}</div>
                      </div>
                    ))}
                  </div>
                  <div style={{ display:'flex', justifyContent:'space-between', alignItems:'flex-end', paddingTop:20, borderTop:'1px solid #c5d8f0' }}>
                    <div>
                      <div style={{ fontSize:11, color:'#4a6080', marginBottom:4 }}>Certificate ID</div>
                      <div style={{ fontSize:12, fontFamily:'monospace', color:'#0a1628' }}>{selected.certificateId}</div>
                    </div>
                    <div style={{ textAlign:'center' }}>
                      <div style={{ borderTop:'2px solid #0a1628', width:160, marginBottom:4 }}></div>
                      <div style={{ fontSize:12, fontWeight:700, color:'#0a1628' }}>ProveRank Team</div>
                      <div style={{ fontSize:11, color:'#4a6080' }}>Authorized Signature</div>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </>
      }
    </div>
  );
}
