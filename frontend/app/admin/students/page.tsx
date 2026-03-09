'use client';
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { getToken } from '@/lib/auth';

const MOCK_STUDENTS = [
  { _id:'s1', name:'Arjun Sharma', email:'arjun@email.com', phone:'9876543210', status:'active', attempts:5, avgScore:678, joinDate:'2024-12-01', rank:1 },
  { _id:'s2', name:'Priya Singh', email:'priya@email.com', phone:'9876543211', status:'active', attempts:4, avgScore:645, joinDate:'2024-12-03', rank:2 },
  { _id:'s3', name:'Rahul Verma', email:'rahul@email.com', phone:'9876543212', status:'active', attempts:5, avgScore:612, joinDate:'2024-12-05', rank:3 },
  { _id:'s4', name:'Sneha Patel', email:'sneha@email.com', phone:'9876543213', status:'inactive', attempts:2, avgScore:480, joinDate:'2024-12-10', rank:45 },
  { _id:'s5', name:'Amit Kumar', email:'amit@email.com', phone:'9876543214', status:'active', attempts:3, avgScore:550, joinDate:'2024-12-15', rank:22 },
];

export default function StudentsPage() {
  const router = useRouter();
  const [students, setStudents] = useState<typeof MOCK_STUDENTS>([]);
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState<'all'|'active'|'inactive'>('all');
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    const fetch_ = async () => {
      try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/admin/students`, {
          headers: { Authorization: `Bearer ${getToken()}` }
        });
        if (res.ok) setStudents(await res.json());
        else setStudents(MOCK_STUDENTS);
      } catch { setStudents(MOCK_STUDENTS); }
    };
    fetch_();
  }, []);

  if (!mounted) return null;

  const filtered = students.filter(s => {
    const matchSearch = s.name.toLowerCase().includes(search.toLowerCase()) || s.email.toLowerCase().includes(search.toLowerCase());
    const matchFilter = filter === 'all' || s.status === filter;
    return matchSearch && matchFilter;
  });

  return (
    <div style={{padding:'20px 16px',color:'#E8F4FF'}}>
      <style>{`@keyframes fadeUp{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:translateY(0)}}`}</style>

      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:16}}>
        <h1 style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:700,color:'#E8F4FF',margin:0}}>👥 Students</h1>
        <div style={{fontSize:12,color:'#4D9FFF',background:'rgba(77,159,255,0.1)',padding:'4px 10px',borderRadius:8,border:'1px solid #002D55'}}>{students.length} total</div>
      </div>

      {/* Search + Filter */}
      <div style={{display:'flex',gap:8,marginBottom:16}}>
        <input value={search} onChange={e=>setSearch(e.target.value)} placeholder="🔍 Search students..."
          style={{flex:1,padding:'10px 12px',background:'#001628',border:'1px solid #002D55',borderRadius:10,color:'#E8F4FF',fontSize:13,outline:'none',fontFamily:'Inter,sans-serif'}}/>
        <select value={filter} onChange={e=>setFilter(e.target.value as typeof filter)}
          style={{padding:'10px 12px',background:'#001628',border:'1px solid #002D55',borderRadius:10,color:'#6B8FAF',fontSize:12,outline:'none',fontFamily:'Inter,sans-serif'}}>
          <option value="all">All</option>
          <option value="active">Active</option>
          <option value="inactive">Inactive</option>
        </select>
      </div>

      {/* Student List */}
      <div style={{display:'flex',flexDirection:'column',gap:8}}>
        {filtered.map((s,i)=>(
          <div key={s._id} style={{background:'#001628',border:'1px solid #002D55',borderRadius:12,padding:'14px',animation:`fadeUp ${0.2+i*0.05}s ease`}}>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:8}}>
              <div>
                <div style={{fontSize:14,fontWeight:600,color:'#E8F4FF'}}>{s.name}</div>
                <div style={{fontSize:11,color:'#6B8FAF'}}>{s.email} · {s.phone}</div>
              </div>
              <span style={{fontSize:10,padding:'3px 8px',borderRadius:6,background:s.status==='active'?'rgba(34,197,94,0.15)':'rgba(107,114,128,0.15)',color:s.status==='active'?'#22C55E':'#6B7280',fontWeight:600,flexShrink:0}}>
                {s.status.toUpperCase()}
              </span>
            </div>
            <div style={{display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:8}}>
              {[{l:'Attempts',v:s.attempts},{l:'Avg Score',v:s.avgScore},{l:'Rank',v:`#${s.rank}`}].map(({l,v})=>(
                <div key={l} style={{textAlign:'center',background:'rgba(0,22,40,0.6)',borderRadius:8,padding:'6px'}}>
                  <div style={{fontSize:14,fontWeight:700,color:'#4D9FFF'}}>{v}</div>
                  <div style={{fontSize:10,color:'#6B8FAF'}}>{l}</div>
                </div>
              ))}
            </div>
            <div style={{display:'flex',gap:6,marginTop:10}}>
              <button style={{flex:1,padding:'7px',background:'rgba(77,159,255,0.1)',border:'1px solid #002D55',borderRadius:8,color:'#4D9FFF',fontSize:11,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>View Results</button>
              <button style={{flex:1,padding:'7px',background:s.status==='active'?'rgba(239,68,68,0.08)':'rgba(34,197,94,0.08)',border:`1px solid ${s.status==='active'?'rgba(239,68,68,0.2)':'rgba(34,197,94,0.2)'}`,borderRadius:8,color:s.status==='active'?'#EF4444':'#22C55E',fontSize:11,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>
                {s.status==='active'?'Deactivate':'Activate'}
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
