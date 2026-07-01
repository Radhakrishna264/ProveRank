'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import PRLogo from '@/components/PRLogo'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const TERMS_VERSION = 'Version 2.1 — Updated March 2026'
const PRI = '#2DD4BF', SUB = '#5EEAD4', TXT = '#CCFBF1'
const CARD = 'rgba(0,35,30,0.78)', BORD = 'rgba(0,200,160,0.22)'

const SECTIONS_EN = [
  { title: '1. Exam Rules & Conduct', content: 'Students must attempt exams in a quiet, well-lit environment. Any form of cheating, including using external resources, sharing questions, or impersonating another student, will result in immediate disqualification and permanent account ban. All exam sessions are monitored by AI-powered proctoring including face detection, tab tracking, and IP verification.' },
  { title: '2. Privacy Policy', content: 'ProveRank collects your name, email, and exam performance data solely for platform operation and analytics. We do not share your personal data with third parties. Webcam snapshots captured during proctoring are used solely for AI-based exam monitoring purposes and are automatically deleted from our database within 24 hours. You may request data deletion at support@proverank.com.' },
  { title: '3. Proctoring Policy', content: 'By starting any exam, you consent to: (a) webcam access for AI-based facial monitoring, (b) tab-switch and window-blur tracking, (c) IP address logging. Disabling your webcam mid-exam or switching tabs will trigger warnings. Three warnings result in automatic exam submission.' },
  { title: '4. Result & Ranking Policy', content: 'All India Ranks are calculated based on score, then time taken. Percentiles follow NEET standard formula. Results are final unless a successful Answer Key Challenge is filed within 48 hours of publication. Re-evaluation requests are processed within 7 working days.' },
  { title: '5. Account & Access Policy', content: 'Each student account is for individual use only. Sharing login credentials is strictly prohibited. Logging in on a new device automatically signs you out of your previous device for security. ProveRank reserves the right to suspend or permanently ban accounts found in violation of any policy.' },
  { title: '6. Refund & Payment Policy', content: 'All purchases (premium plans, test series access) are non-refundable once access has been granted. In case of verified technical failures on our end, credit will be added to your account. Disputes must be raised within 7 days of the transaction.' },
  { title: '7. Data Security & AI Monitoring', content: 'All data is encrypted in transit and at rest. Our AI proctoring system analyses video feed in real-time and does not perform facial recognition for identity storage beyond the active exam session. We never sell or rent your data to advertisers or external companies.' },
  { title: '8. Grievance Redressal', content: 'For any complaints, disputes, or concerns regarding your account, exam results, or data privacy, please contact support@proverank.com. We aim to respond to all grievances within 48 hours and resolve them within 7 working days.' },
]

const SECTIONS_HI = [
  { title: '1. परीक्षा नियम और आचरण', content: 'छात्रों को शांत, अच्छी रोशनी वाले वातावरण में परीक्षा देनी चाहिए। किसी भी प्रकार की नकल, जिसमें बाहरी संसाधनों का उपयोग, प्रश्न साझा करना, या दूसरे छात्र की नकल करना शामिल है, तत्काल अयोग्यता और स्थायी खाता प्रतिबंध का कारण बनेगा।' },
  { title: '2. गोपनीयता नीति', content: 'ProveRank आपका नाम, ईमेल और परीक्षा प्रदर्शन डेटा केवल प्लेटफॉर्म संचालन के लिए एकत्र करता है। हम आपका व्यक्तिगत डेटा तृतीय पक्षों के साथ साझा नहीं करते। प्रोक्टरिंग के दौरान लिए गए वेबकैम स्नैपशॉट केवल AI-आधारित निगरानी हेतु उपयोग होते हैं और हमारे डेटाबेस से 24 घंटों के भीतर स्वचालित रूप से हटा दिए जाते हैं।' },
  { title: '3. प्रोक्टरिंग नीति', content: 'किसी भी परीक्षा को शुरू करके, आप सहमति देते हैं: (a) AI-आधारित चेहरे की निगरानी के लिए वेबकैम एक्सेस, (b) टैब-स्विच ट्रैकिंग, (c) IP एड्रेस लॉगिंग। तीन चेतावनियों के बाद स्वचालित रूप से परीक्षा जमा हो जाती है।' },
  { title: '4. परिणाम और रैंकिंग नीति', content: 'अखिल भारत रैंक स्कोर के आधार पर गणना की जाती है, फिर लिए गए समय के आधार पर। परिणाम प्रकाशन के 48 घंटों के भीतर उत्तर कुंजी चुनौती दायर की जा सकती है। पुनर्मूल्यांकन अनुरोध 7 कार्य दिवसों में संसाधित किए जाते हैं।' },
  { title: '5. खाता और एक्सेस नीति', content: 'प्रत्येक छात्र खाता केवल व्यक्तिगत उपयोग के लिए है। लॉगिन क्रेडेंशियल साझा करना सख्त मना है। नए डिवाइस पर लॉगिन करने से सुरक्षा हेतु आपका पिछला डिवाइस स्वतः लॉगआउट हो जाता है।' },
  { title: '6. रिफंड और भुगतान नीति', content: 'एक्सेस दिए जाने के बाद सभी खरीद अप्रतिदेय हैं। हमारी तकनीकी विफलता के मामले में, क्रेडिट आपके खाते में जोड़ा जाएगा। विवाद लेनदेन के 7 दिनों के भीतर उठाए जाने चाहिए।' },
  { title: '7. डेटा सुरक्षा और AI निगरानी', content: 'सभी डेटा एन्क्रिप्टेड रहता है। हमारा AI प्रोक्टरिंग सिस्टम रीयल-टाइम में वीडियो का विश्लेषण करता है और सक्रिय परीक्षा सत्र के बाद पहचान भंडारण के लिए चेहरा पहचान नहीं करता। हम आपका डेटा कभी भी विज्ञापनदाताओं को नहीं बेचते।' },
  { title: '8. शिकायत निवारण', content: 'अपने खाते, परीक्षा परिणाम, या डेटा गोपनीयता से संबंधित किसी भी शिकायत के लिए कृपया support@proverank.com पर संपर्क करें। हम 48 घंटों के भीतर जवाब देने का प्रयास करते हैं।' },
]

export default function TermsPage() {
  const router = useRouter()
  const [lang, setLang] = useState<'en' | 'hi'>('en')
  const [open, setOpen] = useState<number[]>([])
  const [mounted, setMounted] = useState(false)
  const [scrollPct, setScrollPct] = useState(0)
  const [canAccept, setCanAccept] = useState(false)
  const [accepting, setAccepting] = useState(false)

  useEffect(() => {
    setMounted(true)
    try { const sl = localStorage.getItem('pr_lang') as 'en' | 'hi'; if (sl) setLang(sl) } catch {}
  }, [])

  // F35.15 — Scroll-to-bottom enforcement + progress bar
  useEffect(() => {
    const onScroll = () => {
      const doc = document.documentElement
      const scrollTop = doc.scrollTop || document.body.scrollTop
      const scrollHeight = doc.scrollHeight - doc.clientHeight
      const pct = scrollHeight > 0 ? Math.min(100, (scrollTop / scrollHeight) * 100) : 100
      setScrollPct(pct)
      if (pct >= 92) setCanAccept(true)
    }
    window.addEventListener('scroll', onScroll)
    onScroll()
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  const toggleLang = () => { const n = lang === 'en' ? 'hi' : 'en'; setLang(n); try { localStorage.setItem('pr_lang', n) } catch {} }
  const toggle = (i: number) => setOpen(o => o.includes(i) ? o.filter(x => x !== i) : [...o, i])
  const sections = lang === 'en' ? SECTIONS_EN : SECTIONS_HI

  // F35.15 — Timestamp + version saved on accept
  const handleAccept = async () => {
    if (!canAccept) return
    setAccepting(true)
    try { localStorage.setItem('pr_terms_accepted', 'true') } catch {}
    try {
      const tk = localStorage.getItem('pr_token')
      if (tk) await fetch(`${API}/api/auth/accept-terms`, { method: 'POST', headers: { Authorization: `Bearer ${tk}` } })
    } catch {}
    const back = new URLSearchParams(window.location.search).get('back')
    if (back) router.push(back); else router.push('/dashboard')
  }

  if (!mounted) return null

  return (
    <div style={{ minHeight: '100vh', background: 'linear-gradient(145deg,#001A1A 0%,#002E2E 50%,#000D0D 100%)', color: TXT, fontFamily: 'Inter,sans-serif' }}>
      <style>{`
        @keyframes fadeUp{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}
        @keyframes glowTeal{0%,100%{filter:drop-shadow(0 0 6px #2DD4BF66)}50%{filter:drop-shadow(0 0 20px #2DD4BFaa)}}
        .tbtn{padding:6px 14px;border-radius:20px;border:1.5px solid rgba(0,200,160,.35);background:rgba(0,20,18,.6);color:${TXT};font-size:13px;font-weight:600;cursor:pointer;transition:all 0.2s;backdrop-filter:blur(8px);}
        .tbtn:hover{border-color:${PRI};background:rgba(45,212,191,0.15);}
        .lb{width:100%;padding:15px;border-radius:10px;border:none;background:linear-gradient(135deg,${PRI},#0D9488);color:#001A1A;font-size:16px;font-weight:700;cursor:pointer;box-shadow:0 4px 20px rgba(45,212,191,0.4);transition:all 0.3s;}
        .lb:hover:not(:disabled){transform:translateY(-2px);}
        .lb:disabled{opacity:.4;cursor:not-allowed;box-shadow:none}
      `}</style>

      {/* F35.15 — Scroll progress bar */}
      <div style={{ position: 'fixed', top: 0, left: 0, height: 3, width: `${scrollPct}%`, background: `linear-gradient(90deg,${PRI},#00C48C)`, zIndex: 60, transition: 'width .1s linear' }} />

      <div style={{ borderBottom: `1px solid ${BORD}`, padding: '18px 5%', display: 'flex', justifyContent: 'space-between', alignItems: 'center', position: 'sticky', top: 0, background: 'rgba(0,12,11,0.92)', backdropFilter: 'blur(20px)', zIndex: 50 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <button onClick={() => router.back()} style={{ background: 'none', border: 'none', color: PRI, cursor: 'pointer', fontSize: 20 }}>←</button>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{ animation: 'glowTeal 3s ease-in-out infinite' }}><PRLogo size={26} /></div>
            <span style={{ fontFamily: 'Playfair Display,serif', fontSize: 17, fontWeight: 700, color: PRI }}>ProveRank</span>
          </div>
        </div>
        <button className="tbtn" onClick={toggleLang}>{lang === 'en' ? '🇮🇳 EN' : '🌐 हिंदी'}</button>
      </div>

      <div style={{ maxWidth: 800, margin: '0 auto', padding: '40px 5% 60px' }}>
        <div style={{ textAlign: 'center', marginBottom: 40, animation: 'fadeUp 0.6s ease forwards' }}>
          <h1 style={{ fontFamily: 'Playfair Display,serif', fontSize: 'clamp(1.8rem,4vw,2.6rem)', fontWeight: 700, marginBottom: 10, color: TXT }}>
            {lang === 'en' ? 'Terms & Conditions' : 'नियम और शर्तें'}
          </h1>
          {/* F35.15 — Version tracking */}
          <p style={{ color: PRI, fontSize: 12, fontWeight: 700, letterSpacing: 0.5 }}>{TERMS_VERSION}</p>
          <p style={{ color: SUB, fontSize: 15, marginTop: 14, maxWidth: 520, margin: '14px auto 0' }}>
            {lang === 'en' ? 'Please scroll through and read all terms carefully before accepting.' : 'स्वीकार करने से पहले कृपया सभी नियम ध्यान से पढ़ें।'}
          </p>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginBottom: 36 }}>
          {sections.map((s, i) => (
            <div key={i} style={{ background: CARD, border: `1px solid ${open.includes(i) ? 'rgba(45,212,191,0.45)' : BORD}`, borderRadius: 14, overflow: 'hidden', transition: 'all 0.3s', backdropFilter: 'blur(20px)' }}>
              <button onClick={() => toggle(i)} style={{ width: '100%', padding: '18px 22px', background: 'none', border: 'none', color: TXT, display: 'flex', justifyContent: 'space-between', alignItems: 'center', cursor: 'pointer', fontWeight: 600, fontSize: 15, textAlign: 'left', fontFamily: 'Inter,sans-serif' }}>
                {s.title}
                <span style={{ color: PRI, fontSize: 20, fontWeight: 300, transition: 'transform 0.3s', transform: open.includes(i) ? 'rotate(45deg)' : 'none', display: 'inline-block' }}>+</span>
              </button>
              {open.includes(i) && (
                <div style={{ padding: '0 22px 18px', color: SUB, fontSize: 14, lineHeight: 1.8, borderTop: `1px solid ${BORD}`, paddingTop: 14 }}>
                  {s.content}
                </div>
              )}
            </div>
          ))}
        </div>

        {!canAccept && (
          <div style={{ textAlign: 'center', fontSize: 12, color: SUB, marginBottom: 14 }}>
            ⬇ {lang === 'en' ? 'Scroll to the bottom to enable Accept' : 'स्वीकार करने हेतु नीचे स्क्रॉल करें'} ({Math.round(scrollPct)}%)
          </div>
        )}

        <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap' }}>
          <button className="lb" onClick={handleAccept} disabled={!canAccept || accepting} style={{ flex: 1, minWidth: 200 }}>
            {accepting ? '...' : `✓ ${lang === 'en' ? 'I Accept All Terms' : 'मैं सभी शर्तें स्वीकार करता/करती हूं'}`}
          </button>
          <button onClick={() => router.back()} style={{ flex: 1, minWidth: 200, padding: 15, borderRadius: 10, border: `1.5px solid ${BORD}`, background: 'transparent', color: SUB, fontSize: 16, fontWeight: 600, cursor: 'pointer', fontFamily: 'Inter,sans-serif' }}>
            {lang === 'en' ? 'Decline' : 'अस्वीकार करें'}
          </button>
        </div>
      </div>
    </div>
  )
}
