'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'

const _gt = ():string => { try { return localStorage.getItem('pr_token')||'' } catch { return '' } }
const _gl = ():string => { try { return localStorage.getItem('pr_lang')||'en' } catch { return 'en' } }
const PRI='#4D9FFF'; const SUC='#00C48C'; const GLD='#FFD700'; const SUB='#6B8FAF'; const TXT='#E8F4FF'

export default function OnboardingPage() {
  const router = useRouter()
  const [step, setStep] = useState(0)
  const [mounted, setMounted] = useState(false)
  const lang = typeof window!=='undefined' ? _gl() : 'en'
  const t = (en:string, hi:string) => lang==='en' ? en : hi

  useEffect(()=>{
    if(!_gt()){router.replace('/login');return}
    setMounted(true)
  },[router])

  const steps=[
    {icon:'🎯',en:'Welcome to ProveRank!',hi:'ProveRank में स्वागत है!',de:'India\'s most advanced NEET preparation platform.',dh:'भारत का सबसे उन्नत NEET तैयारी प्लेटफ़ॉर्म।'},
    {icon:'📝',en:'Take Mock Tests',hi:'मॉक टेस्ट दें',de:'Full NEET mocks, chapter tests, and PYQs with AI proctoring.',dh:'AI प्रॉक्टरिंग के साथ पूर्ण NEET मॉक, अध्याय टेस्ट।'},
    {icon:'📊',en:'Track Your Progress',hi:'प्रगति ट्रैक करें',de:'Detailed analytics — subject performance, weak chapters, score trend.',dh:'विस्तृत विश्लेषण — विषय प्रदर्शन, कमजोर अध्याय।'},
    {icon:'🏆',en:'Win Certificates & Rank',hi:'प्रमाणपत्र और रैंक',de:'Earn certificates, compare on All India Leaderboard, share results!',dh:'प्रमाणपत्र अर्जित करें, अखिल भारत लीडरबोर्ड पर रैंक करें!'},
    {icon:'🧠',en:'Smart Revision AI',hi:'स्मार्ट रिवीजन AI',de:'AI analyzes weak areas and suggests personalized 7-day study plans.',dh:'AI कमजोर क्षेत्रों का विश्लेषण करता है।'},
    {icon:'🚀',en:"You're All Set!",hi:'आप तैयार हैं!',de:'Start your first exam, set your target rank, and prove your rank!',dh:'पहली परीक्षा दें, लक्ष्य रैंक सेट करें!'},
  ]
  const s=steps[step]
  const checklist = t('en','hi')==='en'?['Complete your profile','Give your first mock test','Set your target rank','Explore PYQ Bank','Check your analytics']:['प्रोफ़ाइल पूरी करें','पहला मॉक टेस्ट दें','लक्ष्य रैंक सेट करें','PYQ बैंक देखें','एनालिटिक्स जांचें']
  const hrefs=['/profile','/my-exams','/goals','/pyq-bank','/analytics']

  if(!mounted) return null

  return (
    <div style={{minHeight:'100vh',background:'radial-gradient(ellipse at 20% 50%,#001628 0%,#000A18 60%,#000510 100%)',display:'flex',alignItems:'center',justifyContent:'center',fontFamily:'Inter,sans-serif',padding:24,position:'relative',overflow:'hidden'}}>
      <style>{`@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700&display=swap');@keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-8px)}}@keyframes fadeIn{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)}}*{box-sizing:border-box}`}</style>
      {Array.from({length:60},(_,i)=><div key={i} style={{position:'absolute',left:`${(i*137.5)%100}%`,top:`${(i*97.3)%100}%`,width:`${i%3===0?2:1.2}px`,height:`${i%3===0?2:1.2}px`,borderRadius:'50%',background:`rgba(200,218,255,${.08+i%8*.055})`,pointerEvents:'none'}}/>)}
      <div style={{width:'100%',maxWidth:460,animation:'fadeIn .5s ease',position:'relative',zIndex:1}}>
        <div style={{display:'flex',justifyContent:'center',gap:7,marginBottom:22}}>
          {steps.map((_,i)=><div key={i} style={{width:i===step?26:7,height:7,borderRadius:4,background:i===step?PRI:i<step?SUC:'rgba(255,255,255,.15)',transition:'all .3s'}}/>)}
        </div>
        <div style={{background:'rgba(0,22,40,.85)',border:'1px solid rgba(77,159,255,.3)',borderRadius:22,padding:'36px 28px',backdropFilter:'blur(20px)',boxShadow:'0 8px 40px rgba(0,0,0,.5)',textAlign:'center'}}>
          <div style={{fontSize:68,marginBottom:14,animation:'float 3s ease-in-out infinite'}}>{s.icon}</div>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:TXT,marginBottom:9}}>{t(s.en,s.hi)}</div>
          <div style={{fontSize:13,color:SUB,lineHeight:1.7,marginBottom:24}}>{t(s.de,s.dh)}</div>
          {step===steps.length-1&&(
            <div style={{background:'rgba(77,159,255,.06)',border:'1px solid rgba(77,159,255,.15)',borderRadius:13,padding:14,marginBottom:18,textAlign:'left'}}>
              <div style={{fontWeight:700,fontSize:11,color:PRI,marginBottom:9,textTransform:'uppercase',letterSpacing:.5}}>🎯 {t('Getting Started (N3)','शुरुआत चेकलिस्ट')}</div>
              {checklist.map((c,i)=>(
                <a key={i} href={hrefs[i]} style={{display:'flex',alignItems:'center',gap:9,padding:'7px 0',borderBottom:'1px solid rgba(77,159,255,.08)',textDecoration:'none',color:SUB,fontSize:12}}>
                  <span>⭕</span><span>{c}</span><span style={{marginLeft:'auto',color:PRI,fontSize:10}}>→</span>
                </a>
              ))}
            </div>
          )}
          <div style={{display:'flex',gap:9,justifyContent:'center'}}>
            {step>0&&<button onClick={()=>setStep(p=>p-1)} style={{padding:'11px 18px',background:'rgba(77,159,255,.1)',color:PRI,border:'1px solid rgba(77,159,255,.2)',borderRadius:12,cursor:'pointer',fontWeight:700,fontSize:13,fontFamily:'Inter,sans-serif'}}>← {t('Back','वापस')}</button>}
            {step<steps.length-1
              ? <button onClick={()=>setStep(p=>p+1)} style={{flex:1,padding:'13px',background:`linear-gradient(135deg,${PRI},#0055CC)`,color:'#fff',border:'none',borderRadius:12,cursor:'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif'}}>{t('Next →','अगला →')}</button>
              : <button onClick={()=>{try{localStorage.setItem('pr_onboarded','1')}catch{};router.push('/dashboard')}} style={{flex:1,padding:'13px',background:`linear-gradient(135deg,${SUC},#00a87a)`,color:'#000',border:'none',borderRadius:12,cursor:'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif'}}>🚀 {t('Start Journey!','यात्रा शुरू करें!')}</button>
            }
          </div>
          <button onClick={()=>{try{localStorage.setItem('pr_onboarded','1')}catch{};router.push('/dashboard')}} style={{background:'none',border:'none',color:SUB,fontSize:12,cursor:'pointer',marginTop:12,fontFamily:'Inter,sans-serif'}}>{t('Skip tour','टूर छोड़ें')}</button>
        </div>
      </div>
    </div>
  )
}
