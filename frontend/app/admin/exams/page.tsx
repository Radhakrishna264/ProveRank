'use client';
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { getToken } from '@/lib/auth';

const MOCK_EXAMS = [
  { _id:'e1', title:'NEET Mock Series 5', subject:'NEET', questions:180, duration:180, scheduled:'2025-01-15 10:00', status:'completed', attempts:1250, avgScore:487 },
  { _id:'e2', title:'NEET Mock Series 6', subject:'NEET', questions:180, duration:180, scheduled:'2025-01-20 10:00', status:'upcoming', attempts:89, avgScore:0 },
  { _id:'e3', title:'NEET Mock Series 7', subject:'NEET', questions:180, duration:180, scheduled:'2025-01-27 10:00', status:'draft', attempts:0, avgScore:0 },
  { _id:'e4', title:'Chemistry Special Test', subject:'Chemistry', questions:45, duration:60, scheduled:'2025-01-18 14:00', status:'upcoming', attempts:45, avgScore:0 },
];

export default function ExamsPage() {
  const router = useRouter();
  const [exams, setExams] = useState<typeof MOCK_EXAMS>([]);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    const fetch_ = async () => {
      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/admin/exams`, {
          headers: { Authorization: `Bearer ${getToken()}` }
        });
        if (res.ok) setExams(await res.json());
        else setExams(MOCK_EXAMS);
      } catch { setExams(MOCK_EXAMS); }
    };
    fetch_();
  }, []);

  if (!mounted) return null;

  const statusColor: Record<string,string> = { completed:'#22C55E', upcoming:'#4D9FFF', draft:'#6B7280', live:'#F59E0B' };

  return (
    <div style={{padding:'20px 16px',color:'#E8F4FF'}}>
      <style>{`@keyframes fadeUp{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:translateY(0)}}`}</style>

      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:16}}>
        <h1 style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:700,color:'#E8F4FF',margin:0}}>📝 Exams</h1>
        <button style={{padding:'8px 14px',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',border:'none',borderRadius:10,color:'white',fontSize:12,fontWeight:700,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>
          + Create Exam
        </button>
      </div>

      {/* Exam stats row */}
      <div style={{display:'grid',gridTemplateColumns:'repeat(4,1fr)',gap:8,marginBottom:16}}>
        {['All','Live','Upcoming','Draft'].map((s,i)=>(
          <div key={s} style={{textAlign:'center',padding:'8px 4px',background:'#001628',border:'1px solid #002D55',borderRadius:10}}>
            <div style={{fontSize:14,fontWeight:700,color:'#4D9FFF'}}>{[exams.length,exams.filter(e=>e.status==='live').length,exams.filter(e=>e.status==='upcoming').length,exams.filter(e=>e.status==='draft').length][i]}</div>
            <div style={{fontSize:10,color:'#6B8FAF'}}>{s}</div>
          </div>
        ))}
      </div>

      {/* Exam List */}
      <div style={{display:'flex',flexDirection:'column',gap:10}}>
        {exams.map((exam,i)=>(
          <div key={exam._id} style={{background:'#001628',border:'1px solid #002D55',borderRadius:14,padding:'16px',animation:`fadeUp ${0.2+i*0.06}s ease`}}>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:10}}>
              <div style={{flex:1,marginRight:10}}>
                <div style={{fontSize:14,fontWeight:600,color:'#E8F4FF'}}>{exam.title}</div>
                <div style={{fontSize:11,color:'#6B8FAF',marginTop:2}}>{exam.scheduled} · {exam.duration} min · {exam.questions}Q</div>
              </div>
              <span style={{fontSize:10,padding:'3px 8px',borderRadius:6,background:`${statusColor[exam.status]}22`,color:statusColor[exam.status],fontWeight:600,flexShrink:0}}>
                {exam.status.toUpperCase()}
              </span>
            </div>
            <div style={{display:'grid',gridTemplateColumns:'repeat(2,1fr)',gap:8,marginBottom:10}}>
              <div style={{background:'rgba(0,22,40,0.6)',borderRadius:8,padding:'8px',textAlign:'center'}}>
                <div style={{fontSize:16,fontWeight:700,color:'#4D9FFF'}}>{exam.attempts}</div>
                <div style={{fontSize:10,color:'#6B8FAF'}}>Attempts</div>
              </div>
              <div style={{background:'rgba(0,22,40,0.6)',borderRadius:8,padding:'8px',textAlign:'center'}}>
                <div style={{fontSize:16,fontWeight:700,color:'#22C55E'}}>{exam.avgScore||'—'}</div>
                <div style={{fontSize:10,color:'#6B8FAF'}}>Avg Score</div>
              </div>
            </div>
            <div style={{display:'flex',gap:6}}>
              <button style={{flex:1,padding:'7px',background:'rgba(77,159,255,0.1)',border:'1px solid #002D55',borderRadius:8,color:'#4D9FFF',fontSize:11,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>✏️ Edit</button>
              <button style={{flex:1,padding:'7px',background:'rgba(34,197,94,0.08)',border:'1px solid rgba(34,197,94,0.2)',borderRadius:8,color:'#22C55E',fontSize:11,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>📊 Results</button>
              <button style={{flex:1,padding:'7px',background:'rgba(239,68,68,0.08)',border:'1px solid rgba(239,68,68,0.2)',borderRadius:8,color:'#EF4444',fontSize:11,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>🗑️ Delete</button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
