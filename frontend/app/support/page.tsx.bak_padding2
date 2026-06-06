'use client'
import { useState } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const inp:any={width:'100%',padding:'11px 14px',background:'rgba(0,22,40,.85)',border:'1.5px solid rgba(77,159,255,.3)',borderRadius:10,color:'#E8F4FF',fontSize:13,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box',transition:'border-color .2s'}

function SupportSVG() {
  return (
    <svg width="80" height="80" viewBox="0 0 80 80" fill="none" style={{animation:'float 4s ease-in-out infinite',flexShrink:0}}>
      <circle cx="40" cy="40" r="34" stroke="#00C48C" strokeWidth="1.5" fill="none"/>
      <path d="M15 40 Q15 22 32 22 L48 22 Q65 22 65 40 L65 52 Q65 70 48 70 L40 70 L25 80 L25 70 L32 70 Q15 70 15 52 Z" stroke="#00C48C" strokeWidth="1.5" fill="none"/>
      <circle cx="30" cy="46" r="3" fill="#00C48C"/>
      <circle cx="40" cy="46" r="3" fill="#00C48C"/>
      <circle cx="50" cy="46" r="3" fill="#00C48C"/>
    </svg>
  )
}

function SupportContent() {
  const {lang,darkMode:dm,user,toast,token}=useShell()
  const [tab,    setTab]   = useState<'contact'|'feedback'|'faq'|'grievance'|'challenge'|'reeval'>('contact')
  const [msg,    setMsg]   = useState('')
  const [subject,setSubj]  = useState('')
  const [submit, setSubmit]= useState(false)
  const t=(en:string,hi:string)=>lang==='en'?en:hi

  const send=async(type:string)=>{
    if(!msg.trim()){toast(t('Please write a message','कृपया संदेश लिखें'),'e');return}
    setSubmit(true)
    try{
      const r=await fetch(`${API}/api/support/ticket`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({type,message:msg,subject,studentName:user?.name,studentEmail:user?.email})})
      if(r.ok){toast(t('✅ Submitted! We respond within 48 hours.','✅ सबमिट हुआ! 48 घंटों में जवाब देंगे।'),'s');setMsg('');setSubj('')}
      else toast(t('Failed. Please try again.','विफल। पुनः प्रयास करें।'),'e')
    }catch{toast('Network error','e')}
    setSubmit(false)
  }

  const faqs=[
    {q:t('How to start an exam?','परीक्षा कैसे शुरू करें?'),a:t('Go to My Exams → click Start Exam. Webcam + stable internet required.','मेरी परीक्षाएं → परीक्षा शुरू करें। वेबकैम + स्थिर इंटरनेट आवश्यक।')},
    {q:t('Why was my exam auto-submitted?','परीक्षा स्वतः क्यों सबमिट हुई?'),a:t('3 tab-switch warnings trigger auto-submit as per anti-cheat rules.','3 टैब-स्विच चेतावनियों पर anti-cheat नियमानुसार स्वतः सबमिट।')},
    {q:t('When are results published?','परिणाम कब प्रकाशित होते हैं?'),a:t('Results published within 2-3 hours of exam end.','परीक्षा समाप्ति के 2-3 घंटों में।')},
    {q:t('How to download my certificate?','प्रमाणपत्र कैसे डाउनलोड करें?'),a:t('Certificates page → select → Download PDF.','प्रमाणपत्र पेज → चुनें → PDF डाउनलोड।')},
    {q:t('How to challenge an answer key?','उत्तर कुंजी को कैसे चुनौती दें?'),a:t('Support → Answer Key tab → submit objection with reasoning.','Support → Answer Key tab → तर्क के साथ आपत्ति सबमिट।')},
    {q:t('How to set my target rank and track progress?','अपना लक्ष्य रैंक कैसे सेट करें?'),a:t('Go to My Goals page → set target rank/score → save. Progress tracked automatically.','My Goals → लक्ष्य रैंक/स्कोर सेट करें → सहेजें।')},
  ]

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.success},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>🛟 {t('Support & Feedback','सहायता और प्रतिक्रिया')}</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('We are here for you — every question deserves an answer.','हम आपके लिए यहां हैं — हर सवाल का जवाब मिलेगा।')}</div>

      {/* Banner */}
      <div style={{background:'linear-gradient(135deg,rgba(0,196,140,.1),rgba(0,22,40,.88))',border:'1px solid rgba(0,196,140,.22)',borderRadius:20,padding:20,marginBottom:22,display:'flex',alignItems:'center',gap:16,flexWrap:'wrap',position:'relative',overflow:'hidden'}}>
        <SupportSVG/>
        <div style={{flex:1}}>
          <div style={{fontSize:15,color:C.success,fontStyle:'italic',fontWeight:700,marginBottom:4}}>{t('"We are here for you — every question deserves an answer."','"हम आपके लिए यहां हैं — हर सवाल का जवाब मिलेगा।"')}</div>
          <div style={{fontSize:11,color:C.sub}}>{t('Technical issues: <12 hrs | Exam queries: <48 hrs | General: 2-3 days','तकनीकी: <12 घंटे | परीक्षा: <48 घंटे | सामान्य: 2-3 दिन')}</div>
        </div>
      </div>

      {/* Tabs */}
      <div style={{display:'flex',gap:7,marginBottom:18,flexWrap:'wrap'}}>
        {[['contact','📞',t('Contact','संपर्क')],['feedback','💬',t('Feedback','प्रतिक्रिया')],['faq','❓','FAQ'],['grievance','🎫',t('Grievance (S92)','शिकायत')],['challenge','⚔️',t('Answer Key (S69)','उत्तर कुंजी')],['reeval','🔄',t('Re-Eval (S71)','पुनर्मूल्यांकन')]].map(([id,ic,lbl])=>(
          <button key={id} onClick={()=>setTab(id as any)} style={{padding:'8px 14px',borderRadius:10,border:`1px solid ${tab===id?C.primary:C.border}`,background:tab===id?`${C.primary}22`:C.card,color:tab===id?C.primary:C.sub,cursor:'pointer',fontSize:11,fontWeight:tab===id?700:400,fontFamily:'Inter,sans-serif',transition:'all .2s'}}>{ic} {lbl}</button>
        ))}
      </div>

      {/* Contact */}
      {tab==='contact'&&(
        <div>
          <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12,marginBottom:16}}>
            {[
              {icon:'📧',title:t('Support Email','सहायता ईमेल'),val:'ProveRank.support@gmail.com',sub:t('Response: 24-48 hours','प्रतिक्रिया: 24-48 घंटे'),col:C.primary},
              {icon:'💬',title:t('Feedback Email','फ़ीडबैक ईमेल'),val:'ProveRank.feedback@gmail.com',sub:t('Suggestions & improvements','सुझाव और सुधार'),col:C.success},
              {icon:'⚡',title:t('Technical Issues','तकनीकी समस्याएं'),val:`< 12 ${t('hours','घंटे')}`,sub:t('Critical bugs & crashes','गंभीर बग'),col:C.danger},
              {icon:'💡',title:t('General Queries','सामान्य प्रश्न'),val:`2-3 ${t('days','दिन')}`,sub:t('Platform usage & features','प्लेटफ़ॉर्म उपयोग'),col:C.gold},
            ].map((c,i)=>(
              <div key={i} className="card-h" style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:14,padding:18,backdropFilter:'blur(14px)',transition:'all .2s'}}>
                <div style={{fontSize:28,marginBottom:9}}>{c.icon}</div>
                <div style={{fontWeight:700,fontSize:13,color:dm?C.text:C.textL,marginBottom:4}}>{c.title}</div>
                <div style={{fontWeight:700,fontSize:13,color:c.col,marginBottom:4,wordBreak:'break-all'}}>{c.val}</div>
                <div style={{fontSize:11,color:C.sub}}>{c.sub}</div>
              </div>
            ))}
          </div>
          {/* SVG Science decoration */}
          <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:14,padding:18,backdropFilter:'blur(14px)',display:'flex',gap:12,alignItems:'center'}}>
            <svg width="50" height="50" viewBox="0 0 50 50" fill="none" style={{flexShrink:0}}>
              <path d="M10 40 L20 20 L25 30 L30 15 L40 40Z" stroke="#4D9FFF" strokeWidth="1.5" fill="rgba(77,159,255,0.1)" strokeLinejoin="round"/>
              <circle cx="20" cy="20" r="3" fill="#4D9FFF"/>
              <circle cx="30" cy="15" r="3" fill="#FFD700"/>
            </svg>
            <div style={{fontSize:12,color:C.sub,lineHeight:1.6}}>{t('For fastest response, email us at ProveRank.support@gmail.com with your Roll Number and detailed description of the issue.','सबसे तेज़ प्रतिक्रिया के लिए, अपना रोल नंबर और समस्या के विवरण के साथ ProveRank.support@gmail.com पर ईमेल करें।')}</div>
          </div>
        </div>
      )}

      {/* FAQ */}
      {tab==='faq'&&(
        <div>
          {faqs.map((f,i)=>(
            <details key={i} style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:12,marginBottom:8,overflow:'hidden',backdropFilter:'blur(14px)'}}>
              <summary style={{padding:'14px 18px',cursor:'pointer',fontWeight:600,fontSize:13,color:dm?C.text:C.textL,display:'flex',justifyContent:'space-between',alignItems:'center'}}>
                <span>❓ {f.q}</span><span style={{color:C.primary,fontSize:18,transition:'transform .2s'}}>›</span>
              </summary>
              <div style={{padding:'0 18px 14px',fontSize:12,color:C.sub,lineHeight:1.7,borderTop:`1px solid ${C.border}`,paddingTop:10}}>{f.a}</div>
            </details>
          ))}
        </div>
      )}

      {/* Feedback/Grievance/Challenge/Reeval tabs */}
      {(tab==='feedback'||tab==='grievance'||tab==='challenge'||tab==='reeval')&&(
        <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:22,backdropFilter:'blur(14px)'}}>
          <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:C.textL,marginBottom:6}}>
            {tab==='feedback'?`💬 ${t('Share Feedback','प्रतिक्रिया शेयर करें')}`:tab==='grievance'?`🎫 ${t('File a Grievance (S92)','शिकायत दर्ज करें')}`:tab==='challenge'?`⚔️ ${t('Answer Key Challenge (S69)','उत्तर कुंजी चुनौती')}`:`🔄 ${t('Re-Evaluation Request (S71)','पुनर्मूल्यांकन अनुरोध')}`}
          </div>
          <div style={{fontSize:12,color:C.sub,marginBottom:16}}>{t(`Responses sent to: ${user?.email||'your email'}`,'प्रतिक्रिया आपके ईमेल पर भेजी जाएगी')}</div>
          {tab==='challenge'&&(
            <div style={{marginBottom:12}}>
              <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase'}}>Subject / Exam Name</label>
              <input value={subject} onChange={e=>setSubj(e.target.value)} style={inp} placeholder={t('e.g. NEET Mock #12 — Physics Q15','जैसे NEET Mock #12 — Physics Q15')}/>
            </div>
          )}
          <div style={{marginBottom:14}}>
            <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase'}}>{tab==='feedback'?t('Your Feedback','आपकी प्रतिक्रिया'):tab==='grievance'?t('Describe your grievance','शिकायत विस्तार से'):tab==='challenge'?t('Your objection with reasoning','तर्क के साथ आपत्ति'):t('Questions to re-check & reason','पुनः जांच के प्रश्न')}</label>
            <textarea value={msg} onChange={e=>setMsg(e.target.value)} rows={5} placeholder={t('Write clearly and in detail...','स्पष्ट और विस्तार से लिखें...')} style={{...inp,resize:'vertical'}}/>
          </div>
          <button onClick={()=>send(tab)} disabled={submit} className="btn-p" style={{width:'100%',opacity:submit?.7:1}}>
            {submit?'⟳ Submitting...':t('📤 Submit','📤 सबमिट करें')}
          </button>
          <div style={{fontSize:11,color:C.sub,marginTop:10,textAlign:'center'}}>
            {tab==='feedback'?t('Feedback sent to: ProveRank.feedback@gmail.com','प्रतिक्रिया भेजी जाएगी: ProveRank.feedback@gmail.com'):t('Support: ProveRank.support@gmail.com','सहायता: ProveRank.support@gmail.com')}
          </div>
        </div>
      )}

      {/* Footer SVG */}
      <div style={{background:'linear-gradient(135deg,rgba(77,159,255,.07),rgba(0,22,40,.85))',border:`1px solid ${C.border}`,borderRadius:16,padding:20,marginTop:16,textAlign:'center'}}>
        <svg width="200" height="50" viewBox="0 0 200 50" fill="none" style={{display:'block',margin:'0 auto 10px'}}>
          <text x="100" y="35" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="22" fontWeight="700" fill="#4D9FFF" opacity=".7">ProveRank Support</text>
        </svg>
        <div style={{fontSize:12,color:C.sub}}>{t('Average response time: 12-48 hours | Support email: ProveRank.support@gmail.com','औसत प्रतिक्रिया समय: 12-48 घंटे | ईमेल: ProveRank.support@gmail.com')}</div>
      </div>
    </div>
  )
}

export default function SupportPage() {
  return <StudentShell pageKey="support"><SupportContent/></StudentShell>
}
