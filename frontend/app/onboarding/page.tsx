'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const _gt=():string=>{try{return localStorage.getItem('pr_token')||''}catch{return''}}
const _gl=():string=>{try{return localStorage.getItem('pr_lang')||'en'}catch{return'en'}}
const PRI='#4D9FFF',SUC='#00C48C',GLD='#FFD700',PUR='#A78BFA',SUB='#6B8FAF',TXT='#E8F4FF'

export default function OnboardingPage() {
  const router = useRouter()
  const [step,setStep] = useState(0)
  const [mounted,setMounted] = useState(false)
  const lang = typeof window!=='undefined'?_gl():'en'
  const t=(en:string,hi:string)=>lang==='en'?en:hi

  useEffect(()=>{
    if(!_gt()){router.replace('/login');return}
    setMounted(true)
  },[router])

  const steps=[
    {icon:'🚀',color:PRI,en:'Welcome to ProveRank!',hi:'ProveRank में स्वागत है!',desc:t("India's most advanced NEET preparation platform. Real mock tests, AI analytics, and All-India rankings.",'भारत का सबसे उन्नत NEET तैयारी प्लेटफ़ॉर्म।'),svgEl:(
      <svg width="90" height="90" viewBox="0 0 90 90" fill="none" style={{display:'block',margin:'0 auto 16px',animation:'float 4s ease-in-out infinite'}}>
        <circle cx="45" cy="45" r="40" stroke={PRI} strokeWidth="1.5" strokeDasharray="5 4"/>
        <path d="M45 15 C45 15 28 35 24 60 L66 60 C62 35 45 15 45 15Z" fill={`${PRI}44`} stroke={PRI} strokeWidth="1.5"/>
        <circle cx="45" cy="40" r="8" fill="rgba(255,255,255,0.2)" stroke="rgba(255,255,255,0.5)" strokeWidth="1.5"/>
        <path d="M36 60 L20 74 L30 67Z" fill="#0055CC"/>
        <path d="M54 60 L70 74 L60 67Z" fill="#0055CC"/>
        <path d="M38 60 Q45 80 45 80 Q45 80 52 60Z" fill={GLD}/>
      </svg>
    )},
    {icon:'📝',color:PRI,en:'Take Full Mock Tests',hi:'पूर्ण मॉक टेस्ट दें',desc:t('NEET-pattern full mocks (180 Qs/720 marks), chapter tests, and mini tests — all with AI proctoring.','NEET-पैटर्न मॉक (180 प्रश्न/720 अंक), अध्याय टेस्ट, AI प्रॉक्टरिंग के साथ।'),svgEl:(
      <svg width="80" height="80" viewBox="0 0 80 80" fill="none" style={{display:'block',margin:'0 auto 16px',animation:'float 3.5s ease-in-out infinite'}}>
        <rect x="10" y="8" width="60" height="64" rx="6" stroke={PRI} strokeWidth="1.5" fill="rgba(77,159,255,0.1)"/>
        <path d="M10 26h60" stroke={PRI} strokeWidth="1"/>
        {[36,46,56,66].map((y,i)=><rect key={i} x="20" y={y} width={30+i*3} height="5" rx="2.5" fill={PRI} opacity={.5-.08*i}/>)}
        <circle cx="60" cy="18" r="6" fill={SUC} opacity=".8"/>
        <path d="M56 18L59.5 21.5L64 15" stroke="#fff" strokeWidth="1.5" strokeLinecap="round"/>
      </svg>
    )},
    {icon:'📊',color:PUR,en:'AI-Powered Analytics',hi:'AI-संचालित एनालिटिक्स',desc:t('Track subject performance, weak chapters, score trend, and NEET cutoff comparison in real time.','विषय प्रदर्शन, कमजोर अध्याय, स्कोर ट्रेंड और NEET कटऑफ तुलना।'),svgEl:(
      <svg width="80" height="80" viewBox="0 0 80 80" fill="none" style={{display:'block',margin:'0 auto 16px',animation:'float 4s ease-in-out infinite'}}>
        <rect x="5" y="5" width="70" height="70" rx="8" stroke={PUR} strokeWidth="1.5" fill="rgba(167,139,250,0.08)"/>
        <path d="M15 60 L15 15 L65 15" stroke={PUR} strokeWidth="1" strokeLinecap="round"/>
        <path d="M15 55 L28 42 L38 47 L52 28 L65 20" stroke={PRI} strokeWidth="2" strokeLinecap="round" fill="none"/>
        <path d="M15 55 L28 42 L38 47 L52 28 L65 20 L65 55Z" fill={`${PRI}15`}/>
        <circle cx="28" cy="42" r="4" fill={PRI}/>
        <circle cx="52" cy="28" r="4" fill={GLD}/>
        <circle cx="65" cy="20" r="4" fill={SUC}/>
      </svg>
    )},
    {icon:'🏆',color:GLD,en:'All India Rankings',hi:'अखिल भारत रैंकिंग',desc:t('Compete with students across India. Subject-wise leaderboards, percentile ranks, and certificate rewards!','भारत के छात्रों से प्रतिस्पर्धा। सर्टिफिकेट और पर्सेंटाइल रैंक!'),svgEl:(
      <svg width="80" height="85" viewBox="0 0 80 85" fill="none" style={{display:'block',margin:'0 auto 16px',animation:'float 4s ease-in-out infinite'}}>
        <path d="M20 5H60V40Q60 62 40 68Q20 62 20 40Z" stroke={GLD} strokeWidth="1.5" fill={`${GLD}15`}/>
        <path d="M5 12H20V32Q8 30 5 12Z" stroke={GLD} strokeWidth="1" fill={`${GLD}10`}/>
        <path d="M60 12H75V12Q72 30 60 32Z" stroke={GLD} strokeWidth="1" fill={`${GLD}10`}/>
        <line x1="40" y1="68" x2="40" y2="76" stroke={GLD} strokeWidth="2"/>
        <rect x="25" y="76" width="30" height="8" rx="2" stroke={GLD} strokeWidth="1.5" fill={`${GLD}20`}/>
        <path d="M40 22 L43 30H51L45 34L47 43L40 38L33 43L35 34L29 30H37Z" fill={GLD}/>
      </svg>
    )},
    {icon:'🧠',color:PUR,en:'Smart AI Revision',hi:'स्मार्ट AI रिवीजन',desc:t('AI analyses your weak areas and gives a personalized 7-day study plan. Never study the wrong thing again!','AI आपके कमजोर क्षेत्रों का विश्लेषण करता है और 7-दिन की योजना देता है।'),svgEl:(
      <svg width="80" height="80" viewBox="0 0 80 80" fill="none" style={{display:'block',margin:'0 auto 16px',animation:'float 5s ease-in-out infinite'}}>
        <circle cx="40" cy="40" r="34" stroke={PUR} strokeWidth="1.5" fill="rgba(167,139,250,0.08)"/>
        <circle cx="40" cy="40" r="20" stroke={PUR} strokeWidth="1" opacity=".5" fill="none"/>
        {[[40,14],[60,26],[60,54],[40,66],[20,54],[20,26],[40,40]].map(([x,y],i)=>(
          <circle key={i} cx={x} cy={y} r={i===6?6:4} fill={i===6?`${PUR}66`:PUR} stroke={PUR} strokeWidth={i===6?1.5:0}/>
        ))}
        {[[40,14,60,26],[60,26,60,54],[60,54,40,66],[40,66,20,54],[20,54,20,26],[20,26,40,14]].map(([x1,y1,x2,y2],i)=>(
          <line key={i} x1={x1} y1={y1} x2={x2} y2={y2} stroke={PUR} strokeWidth="1" opacity=".4"/>
        ))}
      </svg>
    )},
    {icon:'🎯',color:SUC,en:"You're All Set!",hi:'आप तैयार हैं!',desc:t('Complete your profile, set your target rank, and give your first exam. Your NEET journey starts NOW!','प्रोफ़ाइल पूरी करें, लक्ष्य रैंक सेट करें, और पहला एग्जाम दें!'),svgEl:(
      <svg width="80" height="80" viewBox="0 0 80 80" fill="none" style={{display:'block',margin:'0 auto 16px',animation:'bounce 2s ease-in-out infinite'}}>
        <circle cx="40" cy="40" r="34" stroke={SUC} strokeWidth="1.5" fill="rgba(0,196,140,0.1)"/>
        <path d="M26 40L35 49L54 30" stroke={SUC} strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"/>
        <circle cx="40" cy="40" r="26" stroke={SUC} strokeWidth=".8" opacity=".4" fill="none"/>
      </svg>
    )},
  ]

  const checklist=[
    {en:'Complete your profile',hi:'प्रोफ़ाइल पूरी करें',href:'/profile',icon:'👤'},
    {en:'Give your first mock test',hi:'पहला मॉक टेस्ट दें',href:'/my-exams',icon:'📝'},
    {en:'Set your target rank & score',hi:'लक्ष्य रैंक/स्कोर सेट करें',href:'/goals',icon:'🎯'},
    {en:'Explore PYQ Bank (2015–2024)',hi:'PYQ बैंक देखें',href:'/pyq-bank',icon:'📚'},
    {en:'Check your analytics dashboard',hi:'एनालिटिक्स देखें',href:'/analytics',icon:'📉'},
  ]

  if(!mounted) return null

  const s=steps[step]

  return (
    <div style={{minHeight:'100vh',background:'radial-gradient(ellipse at 15% 55%,#001020,#000A18 50%,#000308)',display:'flex',alignItems:'center',justifyContent:'center',fontFamily:'Inter,sans-serif',padding:24,position:'relative',overflow:'hidden'}}>
      <style>{`@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;600;700&display=swap');*{box-sizing:border-box}@keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-8px)}}@keyframes bounce{0%,100%{transform:translateY(0)}50%{transform:translateY(-12px)}}@keyframes fadeIn{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)}}@keyframes pulse{0%,100%{opacity:.4}50%{opacity:1}}@keyframes shimmer{0%,100%{opacity:.6}50%{opacity:1}}`}</style>
      {/* BG stars */}
      {Array.from({length:55},(_,i)=>(
        <div key={i} style={{position:'absolute',left:`${(i*137.5)%100}%`,top:`${(i*97.3)%100}%`,width:`${i%3===0?2:1.2}px`,height:`${i%3===0?2:1.2}px`,borderRadius:'50%',background:`rgba(200,218,255,${.07+i%8*.045})`,pointerEvents:'none',animation:`pulse ${2+i%4}s ${(i%20)/10}s infinite`}}/>
      ))}
      <div style={{width:'100%',maxWidth:460,animation:'fadeIn .5s ease',position:'relative',zIndex:1}}>
        {/* Step dots */}
        <div style={{display:'flex',justifyContent:'center',gap:7,marginBottom:22}}>
          {steps.map((_,i)=>(
            <div key={i} style={{width:i===step?28:7,height:7,borderRadius:4,background:i===step?s.color:i<step?SUC:'rgba(255,255,255,.15)',transition:'all .3s'}}/>
          ))}
        </div>
        <div style={{background:'rgba(0,22,40,.88)',border:'1px solid rgba(77,159,255,.28)',borderRadius:22,padding:'36px 28px',backdropFilter:'blur(22px)',boxShadow:'0 8px 40px rgba(0,0,0,.55)',textAlign:'center',animation:'fadeIn .4s ease'}}>
          {s.svgEl}
          <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:s.color,marginBottom:10,textShadow:`0 0 20px ${s.color}44`}}>{t(s.en,s.hi)}</div>
          <div style={{fontSize:13,color:SUB,lineHeight:1.7,marginBottom:24}}>{s.desc}</div>

          {/* Last step checklist (N3) */}
          {step===steps.length-1&&(
            <div style={{background:'rgba(77,159,255,.06)',border:'1px solid rgba(77,159,255,.14)',borderRadius:13,padding:14,marginBottom:20,textAlign:'left'}}>
              <div style={{fontWeight:700,fontSize:11,color:PRI,marginBottom:10,textTransform:'uppercase',letterSpacing:.5}}>🎯 {t('Getting Started Checklist (N3)','शुरुआत चेकलिस्ट')}</div>
              {checklist.map((c,i)=>(
                <a key={i} href={c.href} style={{display:'flex',alignItems:'center',gap:10,padding:'8px 0',borderBottom:'1px solid rgba(77,159,255,.07)',textDecoration:'none',color:SUB,fontSize:12,transition:'color .2s'}}>
                  <span style={{fontSize:16}}>{c.icon}</span>
                  <span style={{flex:1}}>{t(c.en,c.hi)}</span>
                  <span style={{color:PRI,fontSize:11}}>→</span>
                </a>
              ))}
            </div>
          )}

          <div style={{display:'flex',gap:9,justifyContent:'center'}}>
            {step>0&&(
              <button onClick={()=>setStep(p=>p-1)} style={{padding:'11px 18px',background:'rgba(77,159,255,.1)',color:PRI,border:'1px solid rgba(77,159,255,.2)',borderRadius:12,cursor:'pointer',fontWeight:700,fontSize:13,fontFamily:'Inter,sans-serif',transition:'all .2s'}}>← {t('Back','वापस')}</button>
            )}
            {step<steps.length-1
              ?<button onClick={()=>setStep(p=>p+1)} style={{flex:1,padding:'13px',background:`linear-gradient(135deg,${s.color},${s.color}88)`,color:s.color===GLD?'#000':'#fff',border:'none',borderRadius:12,cursor:'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif',boxShadow:`0 4px 16px ${s.color}44`,transition:'all .2s'}}>{t('Next →','अगला →')}</button>
              :<button onClick={()=>{try{localStorage.setItem('pr_onboarded','1')}catch{};router.push('/dashboard')}} style={{flex:1,padding:'13px',background:`linear-gradient(135deg,${SUC},#00a87a)`,color:'#000',border:'none',borderRadius:12,cursor:'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif',boxShadow:`0 4px 16px ${SUC}44`}}>🚀 {t('Start My Journey!','यात्रा शुरू करें!')}</button>
            }
          </div>
          <button onClick={()=>{try{localStorage.setItem('pr_onboarded','1')}catch{};router.push('/dashboard')}} style={{background:'none',border:'none',color:SUB,fontSize:12,cursor:'pointer',marginTop:12,fontFamily:'Inter,sans-serif'}}>{t('Skip tour','टूर छोड़ें')}</button>
        </div>
      </div>
    </div>
  )
}
