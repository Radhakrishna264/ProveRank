'use client';
import { useEffect, useRef, useState } from 'react';
import { getToken } from '@/lib/auth';

export default function AdmitCardPage() {
  const [cards,   setCards]   = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<any>(null);
  const printRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/exams/admit-cards`, { headers:{ Authorization:`Bearer ${getToken()}` } })
      .then(r => r.json())
      .then(d => { setCards(Array.isArray(d) ? d : d.admitCards || []); setLoading(false); })
      .catch(() => setLoading(false));
  }, []);

  const handlePrint = () => {
    if (!printRef.current) return;
    const win = window.open('','_blank');
    if (!win) return;
    win.document.write(`<html><head><title>Admit Card — ProveRank</title><style>body{font-family:Inter,sans-serif;background:white;color:#0a1628;margin:0;}*{box-sizing:border-box;}</style></head><body>${printRef.current.innerHTML}</body></html>`);
    win.document.close(); win.print();
  };

  return (
    <div style={{ maxWidth:800, margin:'0 auto' }}>
      <div style={{ fontFamily:'Playfair Display,serif', fontSize:22, color:'var(--text)', marginBottom:4 }}>🎫 Admit Card</div>
      <div style={{ color:'var(--muted)', fontSize:13, marginBottom:24 }}>Apna digital admit card yahan download karo</div>

      {loading ? <div style={{ textAlign:'center', color:'var(--muted)', padding:60 }}>Loading...</div>
       : cards.length === 0
        ? <div style={{ textAlign:'center', background:'var(--card)', border:'1px solid var(--border)', borderRadius:14, padding:60 }}>
            <div style={{ fontSize:48, marginBottom:12 }}>🎫</div>
            <div style={{ color:'var(--muted)', fontSize:14 }}>Koi admit card available nahi hai abhi</div>
            <div style={{ color:'var(--muted)', fontSize:12, marginTop:8 }}>Admin generate karega exam se pehle</div>
          </div>
        : <>
            <div style={{ display:'flex', flexDirection:'column', gap:12, marginBottom:24 }}>
              {cards.map(card => (
                <div key={card._id} onClick={() => setSelected(card)} style={{ background:'var(--card)', border:`1px solid ${selected?._id===card._id?'var(--primary)':'var(--border)'}`, borderRadius:12, padding:'16px 20px', display:'flex', justifyContent:'space-between', alignItems:'center', cursor:'pointer' }}>
                  <div>
                    <div style={{ fontSize:14, fontWeight:600, color:'var(--text)' }}>{card.examId?.title || card.examTitle}</div>
                    <div style={{ fontSize:12, color:'var(--muted)', marginTop:4 }}>Roll No: {card.rollNumber} · {new Date(card.examId?.scheduledFor||Date.now()).toLocaleDateString('en-IN')}</div>
                  </div>
                  <button onClick={e => { e.stopPropagation(); setSelected(card); setTimeout(handlePrint,100); }} style={{ background:'var(--primary)', color:'#000A18', border:'none', borderRadius:8, padding:'8px 16px', cursor:'pointer', fontWeight:600, fontSize:13 }}>📥 Download</button>
                </div>
              ))}
            </div>

            {selected && (
              <div>
                <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:12 }}>
                  <div style={{ fontFamily:'Playfair Display,serif', fontSize:16, color:'var(--text)' }}>Preview</div>
                  <button onClick={handlePrint} style={{ background:'var(--primary)', color:'#000A18', border:'none', borderRadius:8, padding:'8px 18px', cursor:'pointer', fontWeight:600, fontSize:13 }}>🖨️ Print / Download</button>
                </div>
                <div ref={printRef} style={{ background:'white', color:'#0a1628', borderRadius:14, border:'3px solid #1a6fd4', padding:24, fontFamily:'Inter,sans-serif', maxWidth:600, margin:'0 auto' }}>
                  <div style={{ textAlign:'center', borderBottom:'2px solid #1a6fd4', paddingBottom:16, marginBottom:20 }}>
                    <div style={{ fontSize:28, color:'#1a6fd4', fontWeight:900, marginBottom:4 }}>⬡ ProveRank</div>
                    <div style={{ fontSize:18, fontWeight:700 }}>HALL TICKET / ADMIT CARD</div>
                    <div style={{ fontSize:13, color:'#4a6080', marginTop:4 }}>{selected.examId?.title || selected.examTitle}</div>
                  </div>
                  <div style={{ display:'flex', gap:20, marginBottom:20 }}>
                    <div style={{ flex:1 }}>
                      {[['Student Name',selected.studentName],['Roll Number',selected.rollNumber],['Email',selected.studentEmail],['Exam Date',new Date(selected.examId?.scheduledFor||Date.now()).toLocaleString('en-IN')],['Duration',`${selected.examId?.duration||0} minutes`],['Total Marks',`${selected.examId?.totalMarks||0}`]].map(([lbl,val])=>(
                        <div key={lbl} style={{ display:'flex', borderBottom:'1px solid #e0e8f0', padding:'8px 0' }}>
                          <div style={{ width:130, fontSize:12, color:'#4a6080', fontWeight:600 }}>{lbl}:</div>
                          <div style={{ fontSize:13, color:'#0a1628', fontWeight:500 }}>{val}</div>
                        </div>
                      ))}
                    </div>
                    <div style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:12 }}>
                      <div style={{ width:80, height:90, border:'2px solid #1a6fd4', borderRadius:4, background:'#e8f4ff', display:'flex', alignItems:'center', justifyContent:'center', fontSize:32 }}>
                        {selected.studentPhoto ? <img src={selected.studentPhoto} style={{ width:'100%', height:'100%', objectFit:'cover' }} alt="Photo"/> : '👤'}
                      </div>
                      <div style={{ width:80, height:80, border:'2px solid #1a6fd4', borderRadius:4, background:'#f0f4ff', display:'flex', alignItems:'center', justifyContent:'center', fontSize:10, color:'#4a6080', textAlign:'center' }}>
                        {selected.qrCode ? <img src={selected.qrCode} style={{ width:'100%' }} alt="QR"/> : '⬛ QR Code'}
                      </div>
                    </div>
                  </div>
                  <div style={{ background:'#f0f4ff', borderRadius:8, padding:12, marginBottom:16 }}>
                    <div style={{ fontSize:12, fontWeight:700, marginBottom:6 }}>⚠️ IMPORTANT:</div>
                    {['Exam se pehle download karein','Camera aur internet compulsory hai','Kisi ke saath share mat karo'].map((inst,i) => <div key={i} style={{ fontSize:11, color:'#4a6080', marginBottom:3 }}>• {inst}</div>)}
                  </div>
                  <div style={{ textAlign:'center', fontSize:10, color:'#4a6080', borderTop:'1px solid #e0e8f0', paddingTop:12 }}>
                    Generated: {new Date(selected.generatedAt||Date.now()).toLocaleString('en-IN')} · Verify at proverank.com
                  </div>
                </div>
              </div>
            )}
          </>
      }
    </div>
  );
}
