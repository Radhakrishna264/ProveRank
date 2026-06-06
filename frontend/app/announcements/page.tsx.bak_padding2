'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
function AnnouncementsContent() {
  const {lang,darkMode:dm,token}=useShell()
  const [notices,setNotices]=useState<any[]>([])
  const [loading,setLoading]=useState(true)
  const t=(en:string,hi:string)=>lang==='en'?en:hi
  useEffect(()=>{
    if(!token) return
    fetch(`${API}/api/announcements`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{
      const list=Array.isArray(d)?d:[]
      setNotices(list.length?list:[
        {_id:'a1',title:t('Welcome to ProveRank!','ProveRank में आपका स्वागत!'),message:t('Your account is active. Start preparing for NEET 2026 today!','आपका अकाउंट सक्रिय है। आज NEET 2026 की तैयारी शुरू करें!'),createdAt:new Date().toISOString(),type:'update',important:true},
        {_id:'a2',title:t('NEET 2026 Date Announced','NEET 2026 तारीख घोषित'),message:t('NEET 2026 is scheduled for May 3, 2026. Make sure you are prepared!','NEET 2026, 3 मई 2026 को है। सुनिश्चित करें कि आप तैयार हैं!'),createdAt:new Date(Date.now()-86400000).toISOString(),type:'exam'},
      ])
      setLoading(false)
    }).catch(()=>{setNotices([]);setLoading(false)})
  },[token])
  const typeCol:{[k:string]:string}={exam:C.primary,update:C.success,result:C.gold,maintenance:C.warn,urgent:C.danger}
  const typeIcon:{[k:string]:string}={exam:'📝',update:'✨',result:'🏅',maintenance:'🔧',urgent:'🚨'}
  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>📢 {t('Announcements','घोषणाएं')} (S12)</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('Official notices, exam updates & important messages','आधिकारिक सूचनाएं, परीक्षा अपडेट और महत्वपूर्ण संदेश')}</div>
      <div style={{background:'linear-gradient(135deg,rgba(77,159,255,.1),rgba(0,22,40,.88))',border:'1px solid rgba(77,159,255,.2)',borderRadius:18,padding:18,marginBottom:22,display:'flex',alignItems:'center',gap:14}}>
        <svg width="65" height="65" viewBox="0 0 65 65" fill="none" style={{animation:'float 4s ease-in-out infinite',flexShrink:0}}>
          <path d="M10 22 Q10 10 22 10 L43 10 Q55 10 55 22 L55 38 Q55 50 43 50 L32.5 50 L15 60 L15 50 L22 50 Q10 50 10 38 Z" stroke="#4D9FFF" strokeWidth="1.5" fill="rgba(77,159,255,0.1)"/>
          <path d="M20 26h25M20 34h18" stroke="#4D9FFF" strokeWidth="1.5" strokeLinecap="round"/>
          <circle cx="52" cy="8" r="6" fill="#FF4D4D" stroke="rgba(0,22,40,1)" strokeWidth="1.5" style={{animation:'pulse .8s infinite'}}/>
        </svg>
        <div style={{flex:1}}>
          <div style={{fontSize:13,color:C.primary,fontStyle:'italic',fontWeight:700,marginBottom:3}}>{t('"Stay informed, stay ahead — every notice matters."','"सूचित रहो, आगे रहो — हर सूचना महत्वपूर्ण है।"')}</div>
          <div style={{fontSize:11,color:C.sub}}>{notices.length} {t('announcements','घोषणाएं')}</div>
        </div>
      </div>
      {loading?<div style={{textAlign:'center',padding:'30px',color:C.sub,animation:'pulse 1.5s infinite'}}>⟳ Loading...</div>:
        notices.map((n:any)=>(
          <div key={n._id} style={{background:dm?C.card:C.cardL,border:`1px solid ${n.important?(typeCol[n.type||'update']+'55'):C.border}`,borderRadius:13,padding:'15px 18px',marginBottom:12,backdropFilter:'blur(14px)',borderLeft:`4px solid ${typeCol[n.type||'update']||C.primary}`,boxShadow:'0 2px 12px rgba(0,0,0,.12)'}}>
            <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:7,marginBottom:7}}>
              <div style={{display:'flex',alignItems:'center',gap:8}}>
                <span style={{fontSize:16}}>{typeIcon[n.type||'update']||'📢'}</span>
                <span style={{fontWeight:700,fontSize:13,color:dm?C.text:C.textL}}>{n.title}</span>
                {n.important&&<span style={{fontSize:9,padding:'2px 7px',borderRadius:20,background:`${C.danger}15`,color:C.danger,fontWeight:700}}>IMPORTANT</span>}
              </div>
              <span style={{fontSize:10,color:C.sub}}>{n.createdAt?new Date(n.createdAt).toLocaleDateString('en-IN',{day:'numeric',month:'short',year:'numeric'}):''}</span>
            </div>
            <div style={{fontSize:12,color:C.sub,lineHeight:1.7}}>{n.message}</div>
          </div>
        ))
      }
    </div>
  )
}
export default function AnnouncementsPage() {
  return <StudentShell pageKey="announcements"><AnnouncementsContent/></StudentShell>
}
