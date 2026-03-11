'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import PRLogo from '@/components/PRLogo'

const SECTIONS_EN = [
  { title:'1. Exam Rules & Conduct', content:'Students must attempt exams in a quiet, well-lit environment. Any form of cheating, including using external resources, sharing questions, or impersonating another student, will result in immediate disqualification and permanent account ban. All exam sessions are monitored by AI-powered proctoring including face detection, tab tracking, and IP verification.' },
  { title:'2. Privacy Policy', content:'ProveRank collects your name, email, phone number, and exam performance data solely for platform operation and analytics. We do not share your personal data with third parties without consent. Webcam snapshots taken during proctoring are stored securely and deleted after 90 days. You may request data deletion at support@proverank.com.' },
  { title:'3. Proctoring Policy', content:'By starting any exam, you consent to: (a) webcam access for facial monitoring, (b) tab-switch and window-blur tracking, (c) IP address logging, (d) screenshot capture every 30 seconds. Disabling your webcam mid-exam or switching tabs will trigger warnings. Three warnings result in automatic exam submission.' },
  { title:'4. Result & Ranking Policy', content:'All India Ranks are calculated based on score, then time taken. Percentiles follow NEET standard formula. Results are final unless a successful Answer Key Challenge is filed within 48 hours of publication. Re-evaluation requests are processed within 7 working days.' },
  { title:'5. Account & Access Policy', content:'Each student account is for individual use only. Sharing login credentials is strictly prohibited. Simultaneous logins from multiple devices during an active exam are blocked. ProveRank reserves the right to suspend or permanently ban accounts found in violation of any policy.' },
  { title:'6. Refund & Payment Policy', content:'All purchases (premium plans, test series access) are non-refundable once access has been granted. In case of verified technical failures on our end, credit will be added to your account. Disputes must be raised within 7 days of the transaction.' },
]

const SECTIONS_HI = [
  { title:'1. परीक्षा नियम और आचरण', content:'छात्रों को शांत, अच्छी रोशनी वाले वातावरण में परीक्षा देनी चाहिए। किसी भी प्रकार की नकल, जिसमें बाहरी संसाधनों का उपयोग, प्रश्न साझा करना, या दूसरे छात्र की नकल करना शामिल है, तत्काल अयोग्यता और स्थायी खाता प्रतिबंध का कारण बनेगा।' },
  { title:'2. गोपनीयता नीति', content:'ProveRank आपका नाम, ईमेल, फोन नंबर और परीक्षा प्रदर्शन डेटा केवल प्लेटफॉर्म संचालन के लिए एकत्र करता है। हम बिना सहमति के आपका व्यक्तिगत डेटा तृतीय पक्षों के साथ साझा नहीं करते। प्रोक्टरिंग के दौरान लिए गए वेबकैम स्नैपशॉट 90 दिनों के बाद हटा दिए जाते हैं।' },
  { title:'3. प्रोक्टरिंग नीति', content:'किसी भी परीक्षा को शुरू करके, आप सहमति देते हैं: (a) चेहरे की निगरानी के लिए वेबकैम एक्सेस, (b) टैब-स्विच ट्रैकिंग, (c) IP एड्रेस लॉगिंग, (d) हर 30 सेकंड में स्क्रीनशॉट। तीन चेतावनियों के बाद स्वचालित रूप से परीक्षा जमा हो जाती है।' },
  { title:'4. परिणाम और रैंकिंग नीति', content:'अखिल भारत रैंक स्कोर के आधार पर गणना की जाती है, फिर लिए गए समय के आधार पर। परिणाम प्रकाशन के 48 घंटों के भीतर उत्तर कुंजी चुनौती दायर की जा सकती है। पुनर्मूल्यांकन अनुरोध 7 कार्य दिवसों में संसाधित किए जाते हैं।' },
  { title:'5. खाता और एक्सेस नीति', content:'प्रत्येक छात्र खाता केवल व्यक्तिगत उपयोग के लिए है। लॉगिन क्रेडेंशियल साझा करना सख्त मना है। सक्रिय परीक्षा के दौरान एकाधिक डिवाइस से एक साथ लॉगिन ब्लॉक है। किसी भी नीति के उल्लंघन में पाए जाने पर ProveRank खाते को निलंबित करने का अधिकार रखता है।' },
  { title:'6. रिफंड और भुगतान नीति', content:'एक्सेस दिए जाने के बाद सभी खरीद अप्रतिदेय हैं। हमारी तकनीकी विफलता के मामले में, क्रेडिट आपके खाते में जोड़ा जाएगा। विवाद लेनदेन के 7 दिनों के भीतर उठाए जाने चाहिए।' },
]

export default function TermsPage() {
  const router = useRouter()
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const [dark, setDark] = useState(true)
  const [open, setOpen] = useState<number[]>([])
  const [mounted, setMounted] = useState(false)

  useEffect(()=>{
    setMounted(true)
    const sl=localStorage.getItem('pr_lang') as 'en'|'hi'; if(sl) setLang(sl)
    const st=localStorage.getItem('pr_theme'); if(st==='light') setDark(false)
  },[])

  const toggleLang = ()=>{ const n=lang==='en'?'hi':'en'; setLang(n); localStorage.setItem('pr_lang',n) }
  const toggleDark = ()=>{ const n=!dark; setDark(n); localStorage.setItem('pr_theme',n?'dark':'light') }
  const toggle = (i:number) => setOpen(o=>o.includes(i)?o.filter(x=>x!==i):[...o,i])

  const sections = lang==='en' ? SECTIONS_EN : SECTIONS_HI

  const handleAccept = () => {
    localStorage.setItem('pr_terms_accepted','true')
    const back = new URLSearchParams(window.location.search).get('back')
    if (back) router.push(back)
    else router.push('/dashboard')
  }

  if (!mounted) return null

  const bg   = dark ? '#000A18' : '#F0F7FF'
  const card = dark ? 'rgba(0,22,40,0.8)'    : 'rgba(255,255,255,0.9)'
  const bord = dark ? 'rgba(77,159,255,0.2)' : 'rgba(77,159,255,0.3)'
  const tm   = dark ? '#E8F4FF' : '#0F172A'
  const ts   = dark ? '#6B8BAF' : '#475569'

  return (
    <div style={{minHeight:'100vh',background:bg,color:tm,fontFamily:'Inter,sans-serif',transition:'background 0.4s'}}>
      <style>{`@keyframes fadeUp{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}.tbtn{padding:6px 14px;border-radius:20px;border:1.5px solid rgba(77,159,255,0.4);background:rgba(0,22,40,0.5);color:#E8F4FF;font-size:13px;font-weight:600;cursor:pointer;transition:all 0.2s;backdrop-filter:blur(8px);}.tbtn:hover{border-color:#4D9FFF;background:rgba(77,159,255,0.15);}.lb{width:100%;padding:15px;border-radius:10px;border:none;background:linear-gradient(135deg,#4D9FFF,#0055CC);color:white;font-size:16px;font-weight:700;cursor:pointer;box-shadow:0 4px 20px rgba(77,159,255,0.4);transition:all 0.3s;}.lb:hover{transform:translateY(-2px);}`}</style>
      {/* Header */}
      <div style={{borderBottom:`1px solid ${bord}`,padding:'20px 5%',display:'flex',justifyContent:'space-between',alignItems:'center',position:'sticky',top:0,background:dark?'rgba(0,10,24,0.92)':'rgba(248,252,255,0.92)',backdropFilter:'blur(20px)',zIndex:50}}>
        <div style={{display:'flex',alignItems:'center',gap:12}}>
          <button onClick={()=>router.back()} style={{background:'none',border:'none',color:'#4D9FFF',cursor:'pointer',fontSize:20}}>←</button>
          <div style={{display:'flex',alignItems:'center',gap:8}}>
            <svg width={28} height={28} viewBox="0 0 64 64"><polygon points={[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return`${32+26*Math.cos(a)},${32+26*Math.sin(a)}`}).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="2"/><text x="32" y="37" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="14" fontWeight="700" fill="#4D9FFF">PR</text></svg>
            <span style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF,#fff,#4D9FFF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}}>ProveRank</span>
          </div>
        </div>
        <div style={{display:'flex',gap:8}}>
          <button className="tbtn" onClick={toggleLang}>{lang==='en'?'🇮🇳 EN':'🌐 हिंदी'}</button>
          <button className="tbtn" onClick={toggleDark}>{dark?'☀️':'🌙'}</button>
        </div>
      </div>
      {/* Content */}
      <div style={{maxWidth:800,margin:'0 auto',padding:'48px 5%'}}>
        <div style={{textAlign:'center',marginBottom:48,animation:'fadeUp 0.6s ease forwards'}}>
          <h1 style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(1.8rem,4vw,2.6rem)',fontWeight:700,marginBottom:12}}>
            {lang==='en'?'Terms & Conditions':'नियम और शर्तें'}
          </h1>
          <p style={{color:ts,fontSize:14}}>{lang==='en'?'Last Updated: March 2026':'अंतिम अपडेट: मार्च 2026'}</p>
          <p style={{color:ts,fontSize:15,marginTop:12,maxWidth:500,margin:'12px auto 0'}}>
            {lang==='en'
              ? 'Please read all terms carefully before using ProveRank.'
              : 'ProveRank का उपयोग करने से पहले सभी नियम ध्यान से पढ़ें।'}
          </p>
        </div>
        {/* Accordion */}
        <div style={{display:'flex',flexDirection:'column',gap:12,marginBottom:48}}>
          {sections.map((s,i)=>(
            <div key={i} style={{background:card,border:`1px solid ${open.includes(i)?'rgba(77,159,255,0.4)':bord}`,borderRadius:14,overflow:'hidden',transition:'all 0.3s'}}>
              <button onClick={()=>toggle(i)} style={{width:'100%',padding:'20px 24px',background:'none',border:'none',color:tm,display:'flex',justifyContent:'space-between',alignItems:'center',cursor:'pointer',fontWeight:600,fontSize:16,textAlign:'left',fontFamily:'Inter,sans-serif'}}>
                {s.title}
                <span style={{color:'#4D9FFF',fontSize:20,fontWeight:300,transition:'transform 0.3s',transform:open.includes(i)?'rotate(45deg)':'none',display:'inline-block'}}>+</span>
              </button>
              {open.includes(i) && (
                <div style={{padding:'0 24px 20px',color:ts,fontSize:15,lineHeight:1.8,borderTop:`1px solid ${bord}`,paddingTop:16}}>
                  {s.content}
                </div>
              )}
            </div>
          ))}
        </div>
        {/* Accept / Decline */}
        <div style={{display:'flex',gap:16,flexWrap:'wrap'}}>
          <button className="lb" onClick={handleAccept} style={{flex:1,minWidth:200}}>
            ✓ {lang==='en'?'I Accept All Terms':'मैं सभी शर्तें स्वीकार करता/करती हूं'}
          </button>
          <button onClick={()=>router.back()} style={{flex:1,minWidth:200,padding:15,borderRadius:10,border:`1.5px solid ${bord}`,background:'transparent',color:ts,fontSize:16,fontWeight:600,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>
            {lang==='en'?'Decline':'अस्वीकार करें'}
          </button>
        </div>
      </div>
    </div>
  )
}
