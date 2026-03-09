'use client';
import { useState, useEffect } from 'react';
import { getToken } from '@/lib/auth';

const MOCK_QUESTIONS = [
  { _id:'q1', subject:'Physics', topic:'Mechanics', question:'A body is thrown vertically upward. Its velocity at highest point is:', optionA:'Maximum', optionB:'Zero', optionC:'Minimum non-zero', optionD:'Equal to initial', correctAnswer:'B', difficulty:'easy', usedIn:3 },
  { _id:'q2', subject:'Chemistry', topic:'Atomic Structure', question:'The number of electrons in the outermost shell of Sodium is:', optionA:'1', optionB:'2', optionC:'8', optionD:'11', correctAnswer:'A', difficulty:'easy', usedIn:5 },
  { _id:'q3', subject:'Biology', topic:'Cell Biology', question:'Which organelle is responsible for protein synthesis?', optionA:'Mitochondria', optionB:'Ribosome', optionC:'Nucleus', optionD:'Golgi body', correctAnswer:'B', difficulty:'medium', usedIn:4 },
  { _id:'q4', subject:'Physics', topic:'Optics', question:'Critical angle depends upon:', optionA:'Wavelength only', optionB:'Nature of medium only', optionC:'Both wavelength and medium', optionD:'Neither', correctAnswer:'C', difficulty:'hard', usedIn:2 },
];

export default function QuestionsPage() {
  const [questions, setQuestions] = useState<typeof MOCK_QUESTIONS>([]);
  const [search, setSearch] = useState('');
  const [subjectFilter, setSubjectFilter] = useState('all');
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    const fetch_ = async () => {
      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/admin/questions`, {
          headers: { Authorization: `Bearer ${getToken()}` }
        });
        if (res.ok) setQuestions(await res.json());
        else setQuestions(MOCK_QUESTIONS);
      } catch { setQuestions(MOCK_QUESTIONS); }
    };
    fetch_();
  }, []);

  if (!mounted) return null;

  const filtered = questions.filter(q => {
    const matchSearch = q.question.toLowerCase().includes(search.toLowerCase()) || q.topic.toLowerCase().includes(search.toLowerCase());
    const matchSubject = subjectFilter === 'all' || q.subject === subjectFilter;
    return matchSearch && matchSubject;
  });

  const diffColor: Record<string,string> = { easy:'#22C55E', medium:'#F59E0B', hard:'#EF4444' };

  return (
    <div style={{padding:'20px 16px',color:'#E8F4FF'}}>
      <style>{`@keyframes fadeUp{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:translateY(0)}}`}</style>

      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:16}}>
        <h1 style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:700,color:'#E8F4FF',margin:0}}>❓ Questions</h1>
        <button style={{padding:'8px 14px',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',border:'none',borderRadius:10,color:'white',fontSize:12,fontWeight:700,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>
          + Add Question
        </button>
      </div>

      {/* Filters */}
      <div style={{display:'flex',gap:8,marginBottom:16}}>
        <input value={search} onChange={e=>setSearch(e.target.value)} placeholder="🔍 Search questions..."
          style={{flex:1,padding:'10px 12px',background:'#001628',border:'1px solid #002D55',borderRadius:10,color:'#E8F4FF',fontSize:13,outline:'none',fontFamily:'Inter,sans-serif'}}/>
        <select value={subjectFilter} onChange={e=>setSubjectFilter(e.target.value)}
          style={{padding:'10px 12px',background:'#001628',border:'1px solid #002D55',borderRadius:10,color:'#6B8FAF',fontSize:12,outline:'none',fontFamily:'Inter,sans-serif'}}>
          <option value="all">All</option>
          <option value="Physics">Physics</option>
          <option value="Chemistry">Chemistry</option>
          <option value="Biology">Biology</option>
        </select>
      </div>

      {/* Stats */}
      <div style={{display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:8,marginBottom:16}}>
        {['Physics','Chemistry','Biology'].map(s=>(
          <div key={s} style={{textAlign:'center',padding:'8px 4px',background:'#001628',border:'1px solid #002D55',borderRadius:10}}>
            <div style={{fontSize:14,fontWeight:700,color:'#4D9FFF'}}>{questions.filter(q=>q.subject===s).length}</div>
            <div style={{fontSize:10,color:'#6B8FAF'}}>{s}</div>
          </div>
        ))}
      </div>

      {/* Question List */}
      <div style={{display:'flex',flexDirection:'column',gap:8}}>
        {filtered.map((q,i)=>(
          <div key={q._id} style={{background:'#001628',border:'1px solid #002D55',borderRadius:12,padding:'14px',animation:`fadeUp ${0.2+i*0.05}s ease`}}>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:8}}>
              <div style={{flex:1,marginRight:8}}>
                <div style={{display:'flex',gap:6,marginBottom:6,flexWrap:'wrap'}}>
                  <span style={{fontSize:10,padding:'2px 8px',borderRadius:6,background:'rgba(77,159,255,0.15)',color:'#4D9FFF'}}>{q.subject}</span>
                  <span style={{fontSize:10,padding:'2px 8px',borderRadius:6,background:'rgba(107,114,128,0.15)',color:'#6B7280'}}>{q.topic}</span>
                  <span style={{fontSize:10,padding:'2px 8px',borderRadius:6,background:`${diffColor[q.difficulty]}22`,color:diffColor[q.difficulty]}}>{q.difficulty}</span>
                </div>
                <p style={{fontSize:13,color:'#E8F4FF',margin:0,lineHeight:1.5}}>{q.question}</p>
              </div>
            </div>
            <div style={{display:'grid',gridTemplateColumns:'repeat(2,1fr)',gap:4,marginBottom:10}}>
              {['A','B','C','D'].map(opt=>(
                <div key={opt} style={{padding:'5px 8px',borderRadius:6,border:`1px solid ${q.correctAnswer===opt?'#22C55E':'#002D55'}`,background:q.correctAnswer===opt?'rgba(34,197,94,0.1)':'rgba(0,22,40,0.5)',fontSize:11,color:q.correctAnswer===opt?'#22C55E':'#94A3B8'}}>
                  {opt}: {q[`option${opt}` as keyof typeof q]}
                </div>
              ))}
            </div>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'center'}}>
              <span style={{fontSize:11,color:'#6B8FAF'}}>Used in {q.usedIn} exams</span>
              <div style={{display:'flex',gap:6}}>
                <button style={{padding:'5px 10px',background:'rgba(77,159,255,0.1)',border:'1px solid #002D55',borderRadius:6,color:'#4D9FFF',fontSize:11,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>✏️ Edit</button>
                <button style={{padding:'5px 10px',background:'rgba(239,68,68,0.08)',border:'1px solid rgba(239,68,68,0.2)',borderRadius:6,color:'#EF4444',fontSize:11,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>🗑️</button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
