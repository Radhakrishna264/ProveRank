'use client'
import { useState, useEffect } from 'react'
import StudentShell from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const C = { primary:'#4D9FFF', card:'rgba(0,22,40,0.80)', border:'rgba(77,159,255,0.22)', text:'#E8F4FF', sub:'#6B8FAF', success:'#00C48C', gold:'#FFD700', danger:'#FF4D4D', warn:'#FFB84D' }

export default function AnnouncementsPage() {
  return (
    <StudentShell pageKey="announcements">
      {({lang, darkMode:dm, user, toast, token}) => {
        const [notices, setNotices] = useState<any[]>([])
        const [loading, setLoading] = useState(true)

        useEffect(()=>{
          if(!token) return
          fetch(`${API}/api/announcements`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{
            setNotices(Array.isArray(d)?d:[])
            setLoading(false)
          }).catch(()=>{
            setNotices([
              {_id:'a1',title:lang==='en'?'NEET Full Mock #13 Scheduled':'NEET फुल मॉक #13 निर्धारित',message:lang==='en'?'NEET Full Mock Test #13 is scheduled for March 18, 2026. Make sure your webcam and internet are ready.':'NEET फुल मॉक टेस्ट #13 18 मार्च 2026 के लिए निर्धारित है।',createdAt:new Date().toISOString(),type:'exam',important:true},
              {_id:'a2',title:lang==='en'?'PYQ Bank Updated':'PYQ बैंक अपडेट',message:lang==='en'?'NEET 2024 questions have been added to the PYQ Bank. Access them from the PYQ Bank section.':'NEET 2024 प्रश्न PYQ बैंक में जोड़े गए हैं।',createdAt:new Date(Date.now()-86400000).toISOString(),type:'update'},
              {_id:'a3',title:lang==='en'?'Platform Maintenance':'प्लेटफ़ॉर्म रखरखाव',message:lang==='en'?'Scheduled maintenance on March 16, 2026 from 2-4 AM IST. Platform will be unavailable briefly.':'16 मार्च 2026 को रात 2-4 बजे IST रखरखाव।',createdAt:new Date(Date.now()-172800000).toISOString(),type:'maintenance'},
            ])
            setLoading(false)
          })
        },[token])

        const typeColors:{[k:string]:string} = {exam:C.primary,update:C.success,maintenance:C.warn,urgent:C.danger}
        const typeIcons:{[k:string]:string} = {exam:'📝',update:'✨',maintenance:'🔧',urgent:'🚨'}

        return (
          <div style={{animation:'fadeIn .4s ease'}}>
            <div style={{marginBottom:20}}>
              <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>{lang==='en'?'Announcements':'घोषणाएं'} (S12)</h1>
              <div style={{fontSize:13,color:C.sub}}>{lang==='en'?'Official notices, exam updates & important messages':'आधिकारिक सूचनाएं, परीक्षा अपडेट और महत्वपूर्ण संदेश'}</div>
            </div>

            {/* SVG Banner */}
            <div style={{background:'linear-gradient(135deg,rgba(77,159,255,0.1),rgba(0,22,40,0.85))',border:`1px solid rgba(77,159,255,0.2)`,borderRadius:20,padding:'20px',marginBottom:24,display:'flex',alignItems:'center',gap:16,position:'relative',overflow:'hidden'}}>
              <div style={{position:'absolute',right:16,top:'50%',transform:'translateY(-50%)',opacity:.08}}>
                <svg width="120" height="90" viewBox="0 0 120 90" fill="none">
                  <path d="M10 30 Q10 15 25 15 L95 15 Q110 15 110 30 L110 55 Q110 70 95 70 L35 70 L15 85 L15 70 L25 70 Q10 70 10 55 Z" stroke="#4D9FFF" strokeWidth="1.5" fill="none"/>
                  <path d="M25 35h70M25 45h50M25 55h35" stroke="#4D9FFF" strokeWidth="1.5" strokeLinecap="round"/>
                </svg>
              </div>
              <span style={{fontSize:32}}>📢</span>
              <div style={{flex:1}}>
                <div style={{fontSize:14,color:C.primary,fontStyle:'italic',fontWeight:700,marginBottom:3}}>{lang==='en'?'"Stay informed, stay ahead — every notice matters."':'"सूचित रहो, आगे रहो — हर सूचना महत्वपूर्ण है।"'}</div>
                <div style={{fontSize:11,color:C.sub}}>{notices.length} {lang==='en'?'announcements':'घोषणाएं'}</div>
              </div>
            </div>

            {loading?<div style={{textAlign:'center',padding:'40px',color:C.sub}}>⟳ Loading...</div>:notices.length===0?(
              <div style={{textAlign:'center',padding:'60px',background:dm?C.card:'rgba(255,255,255,0.85)',borderRadius:20,border:`1px solid ${C.border}`}}>
                <svg width="60" height="60" viewBox="0 0 60 60" fill="none" style={{display:'block',margin:'0 auto 14px'}}>
                  <path d="M5 25 Q5 12 18 12 L42 12 Q55 12 55 25 L55 40 Q55 53 42 53 L20 53 L5 63 L5 53 Q5 53 5 40 Z" stroke="#4D9FFF" strokeWidth="1.5" fill="none"/>
                </svg>
                <div style={{fontWeight:700,fontSize:15,color:dm?C.text:'#0F172A'}}>{lang==='en'?'No announcements yet':'अभी कोई घोषणाएं नहीं'}</div>
              </div>
            ):(
              notices.map((n:any)=>(
                <div key={n._id} style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${n.important?typeColors[n.type||'update']:C.border}`,borderRadius:14,padding:'16px 20px',marginBottom:12,backdropFilter:'blur(12px)',borderLeft:`4px solid ${typeColors[n.type||'update']||C.primary}`}}>
                  <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:8,marginBottom:8}}>
                    <div style={{display:'flex',alignItems:'center',gap:8}}>
                      <span style={{fontSize:18}}>{typeIcons[n.type||'update']||'📢'}</span>
                      <span style={{fontWeight:700,fontSize:14,color:dm?C.text:'#0F172A'}}>{n.title}</span>
                      {n.important&&<span style={{fontSize:9,padding:'2px 8px',borderRadius:20,background:`${C.danger}15`,color:C.danger,border:`1px solid ${C.danger}30`,fontWeight:700}}>IMPORTANT</span>}
                    </div>
                    <span style={{fontSize:10,color:C.sub}}>{n.createdAt?new Date(n.createdAt).toLocaleDateString('en-IN',{day:'numeric',month:'short',year:'numeric'}):''}</span>
                  </div>
                  <div style={{fontSize:13,color:C.sub,lineHeight:1.6}}>{n.message}</div>
                </div>
              ))
            )}
          </div>
        )
      }}
    </StudentShell>
  )
}
