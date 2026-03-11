'use client'
import { useState, useEffect } from 'react'
import Link from 'next/link'

const API = process.env.NEXT_PUBLIC_API_URL || ''
const DEFAULT_SUPPORT_EMAIL = 'Praveenkumar100806@gmail.com'

const faqs_en = [
  { q:'How is my All India Rank calculated?', a:'Rank is calculated based on your score (higher = better rank). If two students have the same score, the one who finished earlier gets a better rank.' },
  { q:'Can I retake a test after submitting?', a:'No, once submitted, exam cannot be retaken. However, you can view your detailed analysis and the answer key.' },
  { q:'How do I get my certificate?', a:'Certificates are automatically awarded when you meet specific criteria. Visit Dashboard → Certificates to view and download.' },
  { q:'What happens if I lose internet during an exam?', a:'Your answers are auto-saved every 30 seconds. If you reconnect within 5 minutes, you can resume. After 5 minutes, the exam auto-submits.' },
  { q:'How accurate is the proctoring system?', a:'Our AI proctoring detects face, tab switches, and multiple devices. False positives are reviewed manually. You can raise a grievance if flagged incorrectly.' },
]
const faqs_hi = [
  { q:'अखिल भारत रैंक कैसे गणना की जाती है?', a:'रैंक आपके स्कोर के आधार पर गणना की जाती है। यदि दो छात्रों का समान स्कोर है, तो जो पहले समाप्त हुआ उसे बेहतर रैंक मिलती है।' },
  { q:'सबमिट करने के बाद क्या परीक्षा फिर से दे सकते हैं?', a:'नहीं, सबमिट करने के बाद परीक्षा दोबारा नहीं दी जा सकती। हालांकि, आप विस्तृत विश्लेषण और उत्तर कुंजी देख सकते हैं।' },
  { q:'प्रमाण पत्र कैसे प्राप्त करें?', a:'प्रमाण पत्र स्वचालित रूप से दिए जाते हैं जब आप विशिष्ट मानदंड पूरे करते हैं। डैशबोर्ड → प्रमाण पत्र पर जाएं।' },
  { q:'परीक्षा के दौरान इंटरनेट चला जाए तो?', a:'आपके उत्तर हर 30 सेकंड में स्वतः सहेजे जाते हैं। 5 मिनट के भीतर वापस आने पर परीक्षा फिर से शुरू कर सकते हैं।' },
  { q:'प्रोक्टरिंग सिस्टम कितना सटीक है?', a:'हमारा AI प्रोक्टरिंग चेहरा, टैब स्विच और कई डिवाइस का पता लगाता है। गलत फ्लैगिंग के लिए शिकायत दर्ज कर सकते हैं।' },
]

export default function Support() {
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const [dark, setDark] = useState(true)
  const [mounted, setMounted] = useState(false)
  const [tab, setTab] = useState<'contact'|'feedback'|'faq'>('contact')
  const [openFaq, setOpenFaq] = useState<number[]>([])
  const [feedType, setFeedType] = useState('test')
  const [msg, setMsg] = useState('')
  const [subject, setSubject] = useState('')
  const [email, setEmail] = useState('')
  const [submitted, setSubmitted] = useState(false)
  const [loading, setLoading] = useState(false)

  useEffect(()=>{
    setMounted(true)
    const sl=localStorage.getItem('pr_lang') as 'en'|'hi'; if(sl) setLang(sl)
    const st=localStorage.getItem('pr_theme'); if(st==='light') setDark(false)
  },[])

  const toggleLang = ()=>{ const n=lang==='en'?'hi':'en'; setLang(n); localStorage.setItem('pr_lang',n) }
  const toggleDark = ()=>{ const n=!dark; setDark(n); localStorage.setItem('pr_theme',n?'dark':'light') }

  const handleSubmit = async()=>{
    setLoading(true)
    try {
      await fetch(`${API}/api/support/submit`,{
        method:'POST', headers:{'Content-Type':'application/json'},
        body:JSON.stringify({type:feedType, subject, message:msg, email, lang})
      }).catch(()=>{})
      setTimeout(()=>{ setSubmitted(true); setLoading(false) }, 800)
    } catch { setSubmitted(true); setLoading(false) }
  }

  if (!mounted) return null

  const v = {
    bg:   dark ? '#000A18' : '#F0F7FF',
    card: dark ? 'rgba(0,18,36,0.9)' : 'rgba(255,255,255,0.95)',
    bord: dark ? 'rgba(77,159,255,0.14)' : 'rgba(77,159,255,0.25)',
    tm:   dark ? '#E8F4FF' : '#0F172A',
    ts:   dark ? '#6B8BAF' : '#64748B',
    iBg:  dark ? 'rgba(0,22,40,0.8)' : 'rgba(255,255,255,0.9)',
    iBrd: dark ? '#002D55' : '#CBD5E1',
    iClr: dark ? '#E8F4FF' : '#0F172A',
    topbar: dark ? 'rgba(0,6,18,0.96)' : 'rgba(248,252,255,0.96)',
  }

  const faqs = lang==='en' ? faqs_en : faqs_hi

  const feedTypes = lang==='en'
    ? [['test','📝 Test Feedback'],['web','🌐 Website Feedback'],['suggestion','💡 My Suggestion'],['bug','🐛 Report a Bug'],['other','📩 Other']]
    : [['test','📝 परीक्षा प्रतिक्रिया'],['web','🌐 वेबसाइट प्रतिक्रिया'],['suggestion','💡 मेरा सुझाव'],['bug','🐛 बग रिपोर्ट'],['other','📩 अन्य']]

  return (
    <div style={{minHeight:'100vh',background:v.bg,fontFamily:'Inter,sans-serif',color:v.tm}}>
      <style>{`
        @keyframes fadeUp{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}
        .tbtn{padding:6px 14px;border-radius:20px;border:1.5px solid rgba(77,159,255,0.35);background:rgba(77,159,255,0.06);color:${v.ts};font-size:13px;font-weight:600;cursor:pointer;transition:all 0.2s;font-family:Inter,sans-serif;}
        .tbtn:hover{border-color:#4D9FFF;color:#4D9FFF;}
        .lb{padding:13px 28px;border-radius:10px;border:none;background:linear-gradient(135deg,#4D9FFF,#0055CC);color:white;font-size:15px;font-weight:700;cursor:pointer;transition:all 0.3s;font-family:Inter,sans-serif;}
        .lb:hover{transform:translateY(-2px);box-shadow:0 8px 24px rgba(77,159,255,0.4);}
        .s-input{width:100%;padding:13px 16px;border-radius:10px;border:1.5px solid ${v.iBrd};background:${v.iBg};color:${v.iClr};font-size:14px;font-family:Inter,sans-serif;outline:none;transition:border 0.2s;box-sizing:border-box;}
        .s-input:focus{border-color:#4D9FFF;box-shadow:0 0 0 3px rgba(77,159,255,0.12);}
      `}</style>

      {/* Nav */}
      <nav style={{position:'sticky',top:0,zIndex:50,background:v.topbar,backdropFilter:'blur(20px)',borderBottom:`1px solid ${v.bord}`,padding:'0 5%',height:60,display:'flex',alignItems:'center',justifyContent:'space-between'}}>
        <div style={{display:'flex',alignItems:'center',gap:16}}>
          <Link href="/dashboard" style={{textDecoration:'none',color:'#4D9FFF',fontWeight:600,fontSize:14}}>← {lang==='en'?'Back':'वापस'}</Link>
          <div style={{display:'flex',alignItems:'center',gap:8}}>
            <svg width={24} height={24} viewBox="0 0 64 64"><polygon points={[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return`${32+26*Math.cos(a)},${32+26*Math.sin(a)}`}).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="2"/><text x="32" y="37" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="12" fontWeight="700" fill="#4D9FFF">PR</text></svg>
            <span style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:16,color:'#4D9FFF'}}>ProveRank</span>
          </div>
        </div>
        <div style={{display:'flex',gap:8}}>
          <button className="tbtn" onClick={toggleLang}>{lang==='en'?'🇮🇳 हिंदी':'🌐 EN'}</button>
          <button className="tbtn" onClick={toggleDark}>{dark?'☀️':'🌙'}</button>
        </div>
      </nav>

      <div style={{maxWidth:860,margin:'0 auto',padding:'40px 5%',animation:'fadeUp 0.5s ease forwards'}}>
        <div style={{textAlign:'center',marginBottom:40}}>
          <div style={{fontSize:48,marginBottom:12}}>💬</div>
          <h1 style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(1.8rem,4vw,2.6rem)',fontWeight:800,marginBottom:10,color:v.tm}}>
            {lang==='en'?'Support & Feedback':'सहायता और प्रतिक्रिया'}
          </h1>
          <p style={{color:v.ts,fontSize:15,maxWidth:500,margin:'0 auto'}}>
            {lang==='en'
              ? 'We value your feedback. Help us improve ProveRank.'
              : 'आपकी प्रतिक्रिया हमारे लिए मूल्यवान है। ProveRank को बेहतर बनाने में मदद करें।'}
          </p>
        </div>

        {/* Tabs */}
        <div style={{display:'flex',gap:8,marginBottom:28,background:`rgba(77,159,255,0.06)`,borderRadius:14,padding:6,border:`1px solid ${v.bord}`,width:'fit-content',margin:'0 auto 28px'}}>
          {([['contact',lang==='en'?'📞 Contact':'📞 संपर्क'],['feedback',lang==='en'?'💬 Feedback':'💬 प्रतिक्रिया'],['faq',lang==='en'?'❓ FAQ':'❓ FAQ']] as [string,string][]).map(([id,label])=>(
            <button key={id} onClick={()=>setTab(id as any)} style={{padding:'10px 22px',borderRadius:10,border:'none',cursor:'pointer',fontWeight:tab===id?700:500,fontSize:13,fontFamily:'Inter,sans-serif',background:tab===id?'rgba(77,159,255,0.2)':'transparent',color:tab===id?'#4D9FFF':v.ts,transition:'all 0.2s'}}>{label}</button>
          ))}
        </div>

        {/* Contact Tab */}
        {tab==='contact' && (
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(260px,1fr))',gap:16}}>
            <div style={{background:v.card,border:`1px solid ${v.bord}`,borderRadius:18,padding:28}}>
              <div style={{fontSize:32,marginBottom:12}}>📧</div>
              <h3 style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,marginBottom:8,color:v.tm}}>{lang==='en'?'Email Support':'ईमेल सहायता'}</h3>
              <p style={{color:v.ts,fontSize:13,lineHeight:1.7,marginBottom:16}}>{lang==='en'?'For queries, complaints or general support:':'प्रश्नों, शिकायतों या सामान्य सहायता के लिए:'}</p>
              <a href={`mailto:${DEFAULT_SUPPORT_EMAIL}`} style={{color:'#4D9FFF',fontWeight:700,fontSize:14,textDecoration:'none',display:'block',marginBottom:4}}>{DEFAULT_SUPPORT_EMAIL}</a>
              <p style={{color:v.ts,fontSize:12}}>{lang==='en'?'Response within 24–48 hours':'24–48 घंटों में उत्तर'}</p>
            </div>
            <div style={{background:v.card,border:`1px solid ${v.bord}`,borderRadius:18,padding:28}}>
              <div style={{fontSize:32,marginBottom:12}}>⏱️</div>
              <h3 style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,marginBottom:8,color:v.tm}}>{lang==='en'?'Response Time':'उत्तर समय'}</h3>
              {[
                [lang==='en'?'Technical Issues':'तकनीकी समस्याएं','< 12 hours','#FF4757'],
                [lang==='en'?'Exam Grievances':'परीक्षा शिकायतें','< 48 hours','#FFA502'],
                [lang==='en'?'General Queries':'सामान्य प्रश्न','2–3 days','#00C48C'],
              ].map(([label,time,color])=>(
                <div key={String(label)} style={{display:'flex',justifyContent:'space-between',padding:'8px 0',borderBottom:`1px solid ${v.bord}`}}>
                  <span style={{fontSize:13,color:v.ts}}>{label}</span>
                  <span style={{fontWeight:700,fontSize:13,color:String(color)}}>{time}</span>
                </div>
              ))}
            </div>
            <div style={{background:v.card,border:`1px solid ${v.bord}`,borderRadius:18,padding:28}}>
              <div style={{fontSize:32,marginBottom:12}}>📋</div>
              <h3 style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,marginBottom:8,color:v.tm}}>{lang==='en'?'Quick Links':'त्वरित लिंक'}</h3>
              {[
                [lang==='en'?'Answer Key Challenge':'उत्तर कुंजी चुनौती','📝'],
                [lang==='en'?'Re-evaluation Request':'पुनर्मूल्यांकन','🔄'],
                [lang==='en'?'Report Cheat Flag':'धोखाधड़ी रिपोर्ट','🚨'],
                [lang==='en'?'Account Issues':'खाता समस्याएं','👤'],
              ].map(([label,icon])=>(
                <button key={String(label)} onClick={()=>setTab('feedback')} style={{display:'flex',alignItems:'center',gap:10,width:'100%',padding:'10px 14px',borderRadius:10,border:`1px solid ${v.bord}`,background:'rgba(77,159,255,0.04)',color:v.tm,fontSize:13,fontWeight:500,cursor:'pointer',fontFamily:'Inter,sans-serif',marginBottom:6,transition:'all 0.2s',textAlign:'left'}}
                  onMouseEnter={e=>{e.currentTarget.style.borderColor='rgba(77,159,255,0.3)';e.currentTarget.style.color='#4D9FFF'}}
                  onMouseLeave={e=>{e.currentTarget.style.borderColor=v.bord;e.currentTarget.style.color=v.tm}}>
                  {icon} {label} →
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Feedback Tab */}
        {tab==='feedback' && (
          <div style={{background:v.card,border:`1px solid ${v.bord}`,borderRadius:18,padding:28}}>
            {submitted ? (
              <div style={{textAlign:'center',padding:'40px 0'}}>
                <div style={{fontSize:56,marginBottom:16}}>✅</div>
                <h2 style={{fontFamily:'Playfair Display,serif',fontSize:24,fontWeight:700,color:'#00C48C',marginBottom:10}}>{lang==='en'?'Feedback Submitted!':'प्रतिक्रिया जमा हो गई!'}</h2>
                <p style={{color:v.ts,marginBottom:20}}>{lang==='en'?`We'll review your feedback and respond to ${email||DEFAULT_SUPPORT_EMAIL} within 48 hours.`:`हम आपकी प्रतिक्रिया समीक्षा करेंगे।`}</p>
                <button className="tbtn" onClick={()=>{setSubmitted(false);setMsg('');setSubject('');setEmail('')}} style={{padding:'10px 24px',fontSize:14}}>
                  {lang==='en'?'Submit Another':'एक और भेजें'}
                </button>
              </div>
            ) : (
              <>
                <h2 style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:700,color:v.tm,marginBottom:20}}>{lang==='en'?'Share Your Feedback':'अपनी प्रतिक्रिया साझा करें'}</h2>
                {/* Type selector */}
                <div style={{display:'flex',gap:8,flexWrap:'wrap',marginBottom:20}}>
                  {feedTypes.map(([id,label])=>(
                    <button key={id} onClick={()=>setFeedType(String(id))} style={{padding:'8px 16px',borderRadius:10,border:`2px solid ${feedType===id?'#4D9FFF':v.bord}`,background:feedType===id?'rgba(77,159,255,0.1)':'transparent',color:feedType===id?'#4D9FFF':v.ts,fontWeight:feedType===id?700:500,fontSize:12,cursor:'pointer',fontFamily:'Inter,sans-serif',transition:'all 0.2s'}}>
                      {label}
                    </button>
                  ))}
                </div>
                <div style={{display:'flex',flexDirection:'column',gap:16}}>
                  <div>
                    <label style={{fontSize:12,color:'#4D9FFF',fontWeight:700,display:'block',marginBottom:6,letterSpacing:'0.04em',textTransform:'uppercase'}}>{lang==='en'?'Your Email (optional)':'आपका ईमेल (वैकल्पिक)'}</label>
                    <input type="email" value={email} onChange={e=>setEmail(e.target.value)} className="s-input" placeholder={lang==='en'?'For us to respond to you':'हमें जवाब देने के लिए'}/>
                  </div>
                  <div>
                    <label style={{fontSize:12,color:'#4D9FFF',fontWeight:700,display:'block',marginBottom:6,letterSpacing:'0.04em',textTransform:'uppercase'}}>{lang==='en'?'Subject':'विषय'}</label>
                    <input type="text" value={subject} onChange={e=>setSubject(e.target.value)} className="s-input" placeholder={lang==='en'?'Brief subject line':'संक्षिप्त विषय'}/>
                  </div>
                  <div>
                    <label style={{fontSize:12,color:'#4D9FFF',fontWeight:700,display:'block',marginBottom:6,letterSpacing:'0.04em',textTransform:'uppercase'}}>{lang==='en'?'Your Message':'आपका संदेश'}</label>
                    <textarea value={msg} onChange={e=>setMsg(e.target.value)} className="s-input" rows={6} placeholder={lang==='en'?'Describe your feedback, suggestion or issue in detail...':'अपनी प्रतिक्रिया, सुझाव या समस्या विस्तार से बताएं...'} style={{resize:'vertical'}}/>
                  </div>
                  <div style={{display:'flex',alignItems:'center',gap:8,color:v.ts,fontSize:12,padding:'8px 14px',background:'rgba(77,159,255,0.05)',borderRadius:10}}>
                    📧 {lang==='en'?`Feedback goes to: ${DEFAULT_SUPPORT_EMAIL}`:`प्रतिक्रिया जाएगी: ${DEFAULT_SUPPORT_EMAIL}`}
                  </div>
                  <button className="lb" disabled={!msg||loading} onClick={handleSubmit} style={{width:'fit-content'}}>
                    {loading?'◌ Sending...':lang==='en'?'📤 Submit Feedback':'📤 प्रतिक्रिया जमा करें'}
                  </button>
                </div>
              </>
            )}
          </div>
        )}

        {/* FAQ Tab */}
        {tab==='faq' && (
          <div style={{display:'flex',flexDirection:'column',gap:10}}>
            {faqs.map((f,i)=>(
              <div key={i} style={{background:v.card,border:`1px solid ${openFaq.includes(i)?'rgba(77,159,255,0.35)':v.bord}`,borderRadius:14,overflow:'hidden',transition:'all 0.3s'}}>
                <button onClick={()=>setOpenFaq(o=>o.includes(i)?o.filter(x=>x!==i):[...o,i])} style={{width:'100%',padding:'18px 22px',background:'none',border:'none',color:v.tm,display:'flex',justifyContent:'space-between',alignItems:'center',cursor:'pointer',fontWeight:600,fontSize:14,textAlign:'left',fontFamily:'Inter,sans-serif',gap:12}}>
                  <span>{f.q}</span>
                  <span style={{color:'#4D9FFF',fontSize:20,fontWeight:300,transition:'transform 0.3s',transform:openFaq.includes(i)?'rotate(45deg)':'none',display:'inline-block',flexShrink:0}}>+</span>
                </button>
                {openFaq.includes(i) && (
                  <div style={{padding:'0 22px 18px',color:v.ts,fontSize:14,lineHeight:1.8,borderTop:`1px solid ${v.bord}`,paddingTop:14}}>{f.a}</div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
