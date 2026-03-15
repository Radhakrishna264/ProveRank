'use client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'
const getToken=()=>{try{return localStorage.getItem('pr_token')||''}catch{return ''}}

const C = { primary:'#4D9FFF', card:'rgba(0,22,40,0.85)', border:'rgba(77,159,255,0.25)', text:'#E8F4FF', sub:'#6B8FAF', success:'#00C48C', gold:'#FFD700' }

export default function OnboardingPage() {
  const router = useRouter()
  const [step, setStep] = useState(0)
  const [lang] = useState<'en'|'hi'>((typeof window!=='undefined'&&(localStorage.getItem('pr_lang') as 'en'|'hi'))||'en')

  const steps = [
    { icon:'🎯', titleEn:'Welcome to ProveRank!', titleHi:'ProveRank में आपका स्वागत है!', descEn:'India\'s most advanced NEET preparation platform. Let\'s take a quick tour to get you started!', descHi:'भारत का सबसे उन्नत NEET तैयारी प्लेटफ़ॉर्म। आइए एक त्वरित टूर लेते हैं!' },
    { icon:'📝', titleEn:'Take Mock Tests', titleHi:'मॉक टेस्ट दें', descEn:'Access full NEET mock tests, chapter tests, and PYQs. Real exam experience with AI proctoring.', descHi:'पूर्ण NEET मॉक टेस्ट, अध्याय टेस्ट और PYQ एक्सेस करें।' },
    { icon:'📊', titleEn:'Track Your Progress', titleHi:'प्रगति ट्रैक करें', descEn:'Get detailed analytics — subject performance, weak chapters, score trend, and NEET cutoff comparison.', descHi:'विस्तृत विश्लेषण पाएं — विषय प्रदर्शन, कमजोर अध्याय, स्कोर ट्रेंड।' },
    { icon:'🏆', titleEn:'Win Certificates & Rank', titleHi:'प्रमाणपत्र जीतें', descEn:'Earn achievement certificates, compare your rank on the All India Leaderboard, and share results!', descHi:'उपलब्धि प्रमाणपत्र अर्जित करें और अखिल भारत लीडरबोर्ड पर रैंक करें!' },
    { icon:'🧠', titleEn:'Smart Revision AI', titleHi:'स्मार्ट रिवीजन AI', descEn:'AI analyzes your weak areas and suggests personalized revision topics and 7-day study plans.', descHi:'AI आपके कमजोर क्षेत्रों का विश्लेषण करता है और व्यक्तिगत रिवीजन सुझाव देता है।' },
    { icon:'🚀', titleEn:'You\'re All Set!', titleHi:'आप तैयार हैं!', descEn:'Start your first exam, set your target rank, and prove your rank! NEET 2026 — you can do it!', descHi:'अपनी पहली परीक्षा शुरू करें, लक्ष्य रैंक सेट करें और अपनी रैंक साबित करें!' },
  ]
  const s = steps[step]

  const checklist = lang==='en'?[{done:false,text:'Complete your profile',href:'/profile'},{done:false,text:'Give your first mock test',href:'/my-exams'},{done:false,text:'Set your target rank',href:'/goals'},{done:false,text:'Explore PYQ Bank',href:'/pyq-bank'},{done:false,text:'Check your analytics',href:'/analytics'}]:[{done:false,text:'प्रोफ़ाइल पूरी करें',href:'/profile'},{done:false,text:'पहला मॉक टेस्ट दें',href:'/my-exams'},{done:false,text:'लक्ष्य रैंक सेट करें',href:'/goals'},{done:false,text:'PYQ बैंक देखें',href:'/pyq-bank'},{done:false,text:'एनालिटिक्स जांचें',href:'/analytics'}]

  if(!getToken()){if(typeof window!=='undefined')window.location.href='/login';return null}

  return (
    <div style={{minHeight:'100vh',background:'radial-gradient(ellipse at 20% 50%,#001628 0%,#000A18 60%,#000510 100%)',display:'flex',alignItems:'center',justifyContent:'center',fontFamily:'Inter,sans-serif',padding:24,position:'relative',overflow:'hidden'}}>
      <style>{`@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700&display=swap');@keyframes fadeIn{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)}}@keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-8px)}}*{box-sizing:border-box}`}</style>
      <div style={{position:'absolute',inset:0,overflow:'hidden',pointerEvents:'none'}}>
        {Array.from({length:50},(_,i)=><div key={i} style={{position:'absolute',left:`${Math.random()*100}%`,top:`${Math.random()*100}%`,width:Math.random()*2+1,height:Math.random()*2+1,borderRadius:'50%',background:'rgba(255,255,255,0.6)',opacity:Math.random()*0.5+0.1}}/>)}
      </div>
      <div style={{width:'100%',maxWidth:480,animation:'fadeIn .5s ease',position:'relative',zIndex:1}}>
        {/* Progress dots */}
        <div style={{display:'flex',justifyContent:'center',gap:8,marginBottom:24}}>
          {steps.map((_,i)=><div key={i} style={{width:i===step?28:8,height:8,borderRadius:4,background:i===step?C.primary:i<step?C.success:'rgba(255,255,255,0.15)',transition:'all .3s'}}/>)}
        </div>
        {/* Card */}
        <div style={{background:C.card,border:`1px solid rgba(77,159,255,0.3)`,borderRadius:24,padding:'40px 32px',backdropFilter:'blur(20px)',boxShadow:'0 8px 40px rgba(0,0,0,0.5)',textAlign:'center'}}>
          <div style={{fontSize:72,marginBottom:16,animation:'float 3s ease-in-out infinite'}}>{s.icon}</div>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:24,fontWeight:700,color:C.text,marginBottom:10}}>{lang==='en'?s.titleEn:s.titleHi}</div>
          <div style={{fontSize:14,color:C.sub,lineHeight:1.7,marginBottom:28}}>{lang==='en'?s.descEn:s.descHi}</div>
          {step===steps.length-1&&(
            <div style={{background:'rgba(77,159,255,0.06)',border:`1px solid rgba(77,159,255,0.15)`,borderRadius:14,padding:16,marginBottom:20,textAlign:'left'}}>
              <div style={{fontWeight:700,fontSize:12,color:C.primary,marginBottom:10,letterSpacing:.5,textTransform:'uppercase'}}>🎯 {lang==='en'?'Getting Started Checklist (N3)':'शुरुआत चेकलिस्ट'}</div>
              {checklist.map((c,i)=>(
                <a key={i} href={c.href} style={{display:'flex',alignItems:'center',gap:10,padding:'8px 0',borderBottom:`1px solid rgba(77,159,255,0.1)`,textDecoration:'none',color:C.sub,fontSize:12}}>
                  <span style={{fontSize:16}}>⭕</span><span>{c.text}</span><span style={{marginLeft:'auto',color:C.primary}}>→</span>
                </a>
              ))}
            </div>
          )}
          <div style={{display:'flex',gap:10,justifyContent:'center'}}>
            {step>0&&<button onClick={()=>setStep(p=>p-1)} style={{padding:'11px 20px',background:'rgba(77,159,255,0.1)',color:C.primary,border:`1px solid rgba(77,159,255,0.2)`,borderRadius:12,cursor:'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif'}}>← {lang==='en'?'Back':'वापस'}</button>}
            {step<steps.length-1?(
              <button onClick={()=>setStep(p=>p+1)} style={{flex:1,padding:'13px',background:`linear-gradient(135deg,${C.primary},#0055CC)`,color:'#fff',border:'none',borderRadius:12,cursor:'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif'}}>{lang==='en'?'Next →':'अगला →'}</button>
            ):(
              <button onClick={()=>{localStorage.setItem('pr_onboarded','1');router.push('/dashboard')}} style={{flex:1,padding:'13px',background:`linear-gradient(135deg,${C.success},#00a87a)`,color:'#000',border:'none',borderRadius:12,cursor:'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif'}}>🚀 {lang==='en'?'Start Your Journey!':'यात्रा शुरू करें!'}</button>
            )}
          </div>
          <button onClick={()=>{localStorage.setItem('pr_onboarded','1');router.push('/dashboard')}} style={{background:'none',border:'none',color:C.sub,fontSize:12,cursor:'pointer',marginTop:14,fontFamily:'Inter,sans-serif'}}>{lang==='en'?'Skip tour':'टूर छोड़ें'}</button>
        </div>
      </div>
    </div>
  )
}
