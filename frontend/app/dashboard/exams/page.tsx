'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import DashLayout from '@/components/DashLayout'
import { useAuth } from '@/lib/useAuth'

const API = process.env.NEXT_PUBLIC_API_URL || ''
const mockExams = [
  { _id:'demo1', title:'NEET Full Mock Test #13', scheduledAt: new Date(Date.now()+86400000*3).toISOString(), totalDurationSec:12000, totalMarks:720, status:'upcoming' },
  { _id:'demo2', title:'NEET Chapter Test — Biology', scheduledAt: new Date(Date.now()+86400000*6).toISOString(), totalDurationSec:7200, totalMarks:360, status:'upcoming' },
]

export default function Exams() {
  const { user } = useAuth('student')
  const router = useRouter()
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const [exams, setExams] = useState(mockExams)
  const [mounted, setMounted] = useState(false)

  useEffect(()=>{
    setMounted(true)
    const sl=localStorage.getItem('pr_lang') as 'en'|'hi'; if(sl) setLang(sl)
    if (user) fetch(`${API}/api/exams`,{headers:{Authorization:`Bearer ${user.token}`}}).then(r=>r.json()).then(d=>{ if(Array.isArray(d)&&d.length) setExams(d) }).catch(()=>{})
  },[user])

  const dark = mounted ? localStorage.getItem('pr_theme')!=='light' : true
  const v = { card: dark?'rgba(0,18,36,0.9)':'rgba(255,255,255,0.95)', bord: dark?'rgba(77,159,255,0.14)':'rgba(77,159,255,0.25)', tm: dark?'#E8F4FF':'#0F172A', ts: dark?'#6B8BAF':'#64748B' }

  return (
    <DashLayout title={lang==='en'?'My Exams':'मेरी परीक्षाएं'} subtitle={lang==='en'?'Upcoming & completed exams':'आगामी और पूर्ण परीक्षाएं'}>
      <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(320px,1fr))',gap:18}}>
        {exams.map((ex,i)=>{
          const dt = new Date(ex.scheduledAt)
          const diff = Math.ceil((dt.getTime()-Date.now())/86400000)
          return (
            <div key={i} style={{background:v.card,border:`1px solid ${v.bord}`,borderRadius:18,padding:24,transition:'all 0.3s'}}
              onMouseEnter={e=>{e.currentTarget.style.borderColor='rgba(77,159,255,0.35)';e.currentTarget.style.transform='translateY(-4px)'}}
              onMouseLeave={e=>{e.currentTarget.style.borderColor=v.bord;e.currentTarget.style.transform='none'}}>
              <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:14}}>
                <div style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:v.tm}}>{ex.title}</div>
                <span style={{background:'rgba(77,159,255,0.12)',color:'#4D9FFF',padding:'4px 12px',borderRadius:99,fontSize:11,fontWeight:700,flexShrink:0,marginLeft:8}}>
                  {lang==='en'?'Upcoming':'आगामी'}
                </span>
              </div>
              <div style={{display:'flex',gap:16,color:v.ts,fontSize:12,marginBottom:16,flexWrap:'wrap'}}>
                <span>📅 {dt.toLocaleDateString(lang==='en'?'en-IN':'hi-IN')}</span>
                <span>⏱ {Math.round((ex.totalDurationSec||12000)/60)} {lang==='en'?'min':'मिनट'}</span>
                <span>📊 {ex.totalMarks||720} {lang==='en'?'marks':'अंक'}</span>
                <span style={{color:diff<=3?'#FF4757':'#FFA502',fontWeight:700}}>
                  {diff>0?`${lang==='en'?'In':''}${diff}${lang==='en'?` day${diff>1?'s':''}`:`${lang==='en'?'':'दिन में'}`}`:lang==='en'?'Today!':'आज!'}
                </span>
              </div>
              <div style={{display:'flex',gap:10}}>
                <button onClick={()=>router.push(`/exam/${ex._id}/waiting`)} style={{flex:1,padding:'11px',borderRadius:10,border:'none',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',fontWeight:700,fontSize:13,cursor:'pointer',fontFamily:'Inter,sans-serif',transition:'all 0.3s'}}
                  onMouseEnter={e=>(e.currentTarget.style.transform='translateY(-1px)')}
                  onMouseLeave={e=>(e.currentTarget.style.transform='none')}>
                  {lang==='en'?'View Details →':'विवरण देखें →'}
                </button>
              </div>
            </div>
          )
        })}
      </div>
    </DashLayout>
  )
}
