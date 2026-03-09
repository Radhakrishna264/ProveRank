'use client';
import { useState, useEffect } from 'react';
import { getToken } from '@/lib/auth';

const MOCK_ANNOUNCEMENTS = [
  { _id:'a1', title:'NEET Mock Series 6 Registration Open', message:'Register now for Mock Series 6 on Jan 20.', type:'exam', sentTo:'all', sentAt:'2025-01-12', reads:1120 },
  { _id:'a2', title:'Result of Mock Series 5 Published', message:'Check your result and rank on the results page.', type:'result', sentTo:'all', sentAt:'2025-01-16', reads:980 },
];

export default function AnnouncementsPage() {
  const [announcements, setAnnouncements] = useState<typeof MOCK_ANNOUNCEMENTS>([]);
  const [showForm, setShowForm] = useState(false);
  const [newTitle, setNewTitle] = useState('');
  const [newMsg, setNewMsg] = useState('');
  const [newType, setNewType] = useState('general');
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    setAnnouncements(MOCK_ANNOUNCEMENTS);
  }, []);

  if (!mounted) return null;

  const typeColor: Record<string,string> = { exam:'#4D9FFF', result:'#22C55E', general:'#F59E0B', urgent:'#EF4444' };

  const handleSend = () => {
    if (!newTitle || !newMsg) return;
    setAnnouncements([{_id:`a${Date.now()}`,title:newTitle,message:newMsg,type:newType,sentTo:'all',sentAt:new Date().toISOString().slice(0,10),reads:0}, ...announcements]);
    setNewTitle(''); setNewMsg(''); setShowForm(false);
  };

  return (
    <div style={{padding:'20px 16px',color:'#E8F4FF'}}>
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:16}}>
        <h1 style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:700,color:'#E8F4FF',margin:0}}>📢 Announcements</h1>
        <button onClick={()=>setShowForm(!showForm)}
          style={{padding:'8px 14px',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',border:'none',borderRadius:10,color:'white',fontSize:12,fontWeight:700,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>
          + New
        </button>
      </div>

      {/* New Announcement Form */}
      {showForm && (
        <div style={{background:'#001628',border:'1px solid rgba(77,159,255,0.3)',borderRadius:14,padding:'16px',marginBottom:16}}>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:15,fontWeight:700,color:'#E8F4FF',marginBottom:12}}>📝 New Announcement</div>
          <input value={newTitle} onChange={e=>setNewTitle(e.target.value)} placeholder="Title"
            style={{width:'100%',padding:'10px 12px',background:'rgba(0,22,40,0.8)',border:'1px solid #002D55',borderRadius:8,color:'#E8F4FF',fontSize:13,outline:'none',marginBottom:8,fontFamily:'Inter,sans-serif',boxSizing:'border-box'}}/>
          <textarea value={newMsg} onChange={e=>setNewMsg(e.target.value)} placeholder="Message" rows={3}
            style={{width:'100%',padding:'10px 12px',background:'rgba(0,22,40,0.8)',border:'1px solid #002D55',borderRadius:8,color:'#E8F4FF',fontSize:13,outline:'none',marginBottom:8,fontFamily:'Inter,sans-serif',resize:'none',boxSizing:'border-box'}}/>
          <select value={newType} onChange={e=>setNewType(e.target.value)}
            style={{width:'100%',padding:'10px 12px',background:'rgba(0,22,40,0.8)',border:'1px solid #002D55',borderRadius:8,color:'#6B8FAF',fontSize:12,outline:'none',marginBottom:12,fontFamily:'Inter,sans-serif'}}>
            <option value="general">General</option>
            <option value="exam">Exam</option>
            <option value="result">Result</option>
            <option value="urgent">Urgent</option>
          </select>
          <div style={{display:'flex',gap:8}}>
            <button onClick={handleSend} style={{flex:1,padding:10,background:'linear-gradient(135deg,#4D9FFF,#0055CC)',border:'none',borderRadius:8,color:'white',fontSize:13,fontWeight:700,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>📤 Send to All</button>
            <button onClick={()=>setShowForm(false)} style={{flex:1,padding:10,background:'transparent',border:'1px solid #002D55',borderRadius:8,color:'#6B8FAF',fontSize:13,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>Cancel</button>
          </div>
        </div>
      )}

      {/* Announcement List */}
      <div style={{display:'flex',flexDirection:'column',gap:10}}>
        {announcements.map(a=>(
          <div key={a._id} style={{background:'#001628',border:'1px solid #002D55',borderRadius:12,padding:'14px'}}>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:6}}>
              <div style={{flex:1,marginRight:8}}>
                <div style={{fontSize:14,fontWeight:600,color:'#E8F4FF'}}>{a.title}</div>
                <div style={{fontSize:12,color:'#6B8FAF',marginTop:3,lineHeight:1.5}}>{a.message}</div>
              </div>
              <span style={{fontSize:10,padding:'3px 8px',borderRadius:6,background:`${typeColor[a.type]}22`,color:typeColor[a.type],fontWeight:600,flexShrink:0}}>{a.type.toUpperCase()}</span>
            </div>
            <div style={{display:'flex',justifyContent:'space-between',fontSize:11,color:'#6B8FAF',marginTop:8}}>
              <span>📅 {a.sentAt}</span>
              <span>👁️ {a.reads} reads</span>
              <span>👥 {a.sentTo}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
