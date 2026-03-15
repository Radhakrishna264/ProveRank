'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

function AnnouncementsContent() {
  const { lang, darkMode:dm, token } = useShell()
  const [notices, setNotices] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const t = (en:string, hi:string) => lang==='en' ? en : hi

  useEffect(()=>{
    if(!token) return
    fetch(`${API}/api/announcements`,{headers:{Authorization:`Bearer ${token}`}})
      .then(r=>r.ok?r.json():[]).then(d=>{
        const list=Array.isArray(d)?d:[]
        if(!list.length) setNotices([
          {_id:'a1',title:t('NEET Full Mock #13 Scheduled','NEET फुल मॉक #13 निर्धारित'),message:t('NEET Full Mock Test #13 is scheduled for March 22, 2026. Ensure webcam and internet are ready.','NEET फुल मॉक टेस्ट #13 22 मार्च 2026 के लिए निर्धारित है।'),createdAt:new Date().toISOString(),type:'exam',important:true},
          {_id:'a2',title:t('PYQ Bank Updated with NEET 2024','PYQ बैंक अपडेट'),message:t('NEET 2024 questions have been added to the PYQ Bank section.','NEET 2024 प्रश्न PYQ बैंक में जोड़े गए हैं।'),createdAt:new Date(Date.now()-86400000).toISOString(),type:'update'},
          {_id:'a3',title:t('Result Declaration — Mock #12','परिणाम घोषणा'),message:t('Mock Test #12 results have been published. Check your rank on the Leaderboard.','मॉक टेस्ट #12 के परिणाम प्रकाशित हुए। लीडरबोर्ड पर अपनी रैंक देखें।'),createdAt:new Date(Date.now()-172800000).toISOString(),type:'result'},
        ])
        else setNotices(list)
        setLoading(false)
      }).catch(()=>{
        setNotices([{_id:'a1',title:t('Welcome to ProveRank!','ProveRank में स्वागत!'),message:t('Your account is ready. Start your first exam today!','आपका अकाउंट तैयार है। आज पहली परीक्षा शुरू करें!'),createdAt:new Date().toISOString(),type:'update'}])
        setLoading(false)
      })
  },[token])

  const typeCol:{[k:string]:string}={exam:C.primary,update:C.success,result:C.gold,maintenance:C.warn,urgent:C.danger}
  const typeIcon:{[k:string]:string}={exam:'📝',update:'✨',result:'🏅',maintenance:'🔧',urgent:'🚨'}

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>📢 {t('Announcements','घोषणाएं')} (S12)</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('Official notices, exam updates & important messages','आधिकारिक सूचनाएं, परीक्षा अपडेट और महत्वपूर्ण संदेश')}</div>

      <div style={{background:'linear-gradient(135deg,rgba(77,159,255,.1),rgba(0,22,40,.85))',border:'1px solid rgba(77,159,255,.2)',borderRadius:16,padding:16,marginBottom:22,display:'flex',alignItems:'center',gap:14}}>
        <span style={{fontSize:28}}>📢</span>
        <div>
          <div style={{fontSize:13,color:C.primary,fontStyle:'italic',fontWeight:700}}>{t('"Stay informed, stay ahead — every notice matters."','"सूचित रहो, आगे रहो — हर सूचना महत्वपूर्ण है।"')}</div>
          <div style={{fontSize:11,color:C.sub,marginTop:3}}>{notices.length} {t('announcements','घोषणाएं')}</div>
        </div>
      </div>

      {loading?<div style={{textAlign:'center',padding:'40px',color:C.sub}}>⟳ Loading...</div>:
        notices.map((n:any)=>(
          <div key={n._id} style={{background:dm?C.card:C.cardL,border:`1px solid ${n.important?(typeCol[n.type||'update']||C.primary)+'55':C.border}`,borderRadius:13,padding:'15px 18px',marginBottom:10,backdropFilter:'blur(12px)',borderLeft:`4px solid ${typeCol[n.type||'update']||C.primary}`}}>
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
