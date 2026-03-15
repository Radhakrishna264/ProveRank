'use client'
import { useState } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

function SupportContent() {
  const { lang, darkMode:dm, user, toast, token } = useShell()
  const [tab,    setTab]    = useState<'contact'|'feedback'|'faq'|'grievance'|'challenge'|'reeval'>('contact')
  const [msg,    setMsg]    = useState('')
  const [submit, setSubmit] = useState(false)
  const t = (en:string, hi:string) => lang==='en' ? en : hi

  const sendTicket = async (type:string) => {
    if(!msg.trim()){toast(t('Please write a message','कृपया संदेश लिखें'),'e');return}
    setSubmit(true)
    try {
      const r=await fetch(`${API}/api/support/ticket`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({type,message:msg,studentName:user?.name,studentEmail:user?.email})})
      if(r.ok){toast(t('Submitted! We respond within 48 hours.','सबमिट हुआ! 48 घंटों में जवाब देंगे।'),'s');setMsg('')}
      else toast(t('Failed to submit','सबमिट नहीं हुआ'),'e')
    } catch { toast('Network error','e') }
    setSubmit(false)
  }

  const faqs = [
    {q:t('How to start an exam?','परीक्षा कैसे शुरू करें?'),a:t('Go to My Exams → click Start Exam. Webcam required.','मेरी परीक्षाएं पर जाएं → परीक्षा शुरू करें।')},
    {q:t('Why was my exam auto-submitted?','परीक्षा स्वतः क्यों सबमिट हुई?'),a:t('3 tab-switch warnings trigger auto-submit per exam rules.','3 टैब-स्विच चेतावनियों पर स्वतः सबमिट होती है।')},
    {q:t('When are results published?','परिणाम कब प्रकाशित होते हैं?'),a:t('Results are published within 2-3 hours of exam completion.','परीक्षा समाप्ति के 2-3 घंटों के भीतर।')},
    {q:t('How to download my certificate?','प्रमाणपत्र कैसे डाउनलोड करें?'),a:t('Go to Certificates page → select → Download PDF.','प्रमाणपत्र पेज पर जाएं → चुनें → PDF डाउनलोड।')},
    {q:t('How to challenge an answer key?','उत्तर कुंजी को कैसे चुनौती दें?'),a:t('Go to Support → Answer Key tab and submit with reasoning.','Support → Answer Key tab पर जाएं।')},
  ]

  const inp:any={width:'100%',padding:'11px 14px',background:'rgba(0,22,40,.85)',border:'1.5px solid rgba(77,159,255,.3)',borderRadius:10,color:'#E8F4FF',fontSize:13,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box',resize:'vertical'}

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>🛟 {t('Support & Feedback','सहायता और प्रतिक्रिया')}</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('We are here for you — every question deserves an answer.','हम आपके लिए यहां हैं।')}</div>

      <div style={{display:'flex',gap:7,marginBottom:18,flexWrap:'wrap'}}>
        {[['contact','📞',t('Contact','संपर्क')],['feedback','💬',t('Feedback','प्रतिक्रिया')],['faq','❓','FAQ'],['grievance','🎫',t('Grievance','शिकायत')],['challenge','⚔️',t('Answer Key','उत्तर कुंजी')],['reeval','🔄',t('Re-Eval','पुनर्मूल्यांकन')]].map(([id,ic,label])=>(
          <button key={id} onClick={()=>setTab(id as any)} style={{padding:'8px 13px',borderRadius:9,border:`1px solid ${tab===id?C.primary:C.border}`,background:tab===id?`${C.primary}22`:C.card,color:tab===id?C.primary:C.sub,cursor:'pointer',fontSize:11,fontWeight:tab===id?700:400,fontFamily:'Inter,sans-serif'}}>{ic} {label}</button>
        ))}
      </div>

      {tab==='contact' && (
        <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12}}>
          {[{icon:'📧',title:t('Email Support','ईमेल सहायता'),val:'support@proverank.com',sub:t('24-48 hours response','24-48 घंटों में जवाब'),col:C.primary},{icon:'⚡',title:t('Technical Issues','तकनीकी समस्याएं'),val:`< 12 ${t('hours','घंटे')}`,sub:t('Critical bug response','गंभीर बग'),col:C.danger},{icon:'📋',title:t('Exam Grievances','परीक्षा शिकायतें'),val:`< 48 ${t('hours','घंटे')}`,sub:t('Result disputes','परिणाम विवाद'),col:C.warn},{icon:'💡',title:t('General Queries','सामान्य प्रश्न'),val:`2-3 ${t('days','दिन')}`,sub:t('Platform usage','प्लेटफ़ॉर्म उपयोग'),col:C.success}].map((c,i)=>(
            <div key={i} className="card-h" style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:14,padding:18,backdropFilter:'blur(12px)',transition:'all .2s'}}>
              <div style={{fontSize:26,marginBottom:8}}>{c.icon}</div>
              <div style={{fontWeight:700,fontSize:13,color:dm?C.text:C.textL,marginBottom:4}}>{c.title}</div>
              <div style={{fontWeight:700,fontSize:15,color:c.col,marginBottom:4}}>{c.val}</div>
              <div style={{fontSize:11,color:C.sub}}>{c.sub}</div>
            </div>
          ))}
        </div>
      )}

      {tab==='faq' && (
        <div>
          {faqs.map((f,i)=>(
            <details key={i} style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:11,marginBottom:7,overflow:'hidden',backdropFilter:'blur(12px)'}}>
              <summary style={{padding:'13px 16px',cursor:'pointer',fontWeight:600,fontSize:13,color:dm?C.text:C.textL,listStyle:'none',display:'flex',justifyContent:'space-between'}}>
                <span>❓ {f.q}</span><span style={{color:C.primary}}>▾</span>
              </summary>
              <div style={{padding:'0 16px 13px',fontSize:12,color:C.sub,lineHeight:1.7,borderTop:`1px solid ${C.border}`}}>{f.a}</div>
            </details>
          ))}
        </div>
      )}

      {(tab==='feedback'||tab==='grievance'||tab==='challenge'||tab==='reeval') && (
        <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:22,backdropFilter:'blur(12px)'}}>
          <div style={{fontWeight:700,fontSize:15,color:dm?C.text:C.textL,marginBottom:14}}>
            {tab==='feedback'?`💬 ${t('Share Feedback','प्रतिक्रिया')}`:`${tab==='grievance'?'🎫':tab==='challenge'?'⚔️':'🔄'} ${tab==='grievance'?t('Grievance (S92)','शिकायत'):tab==='challenge'?t('Answer Key Challenge (S69)','उत्तर कुंजी'):t('Re-Evaluation (S71)','पुनर्मूल्यांकन')}`}
          </div>
          <textarea value={msg} onChange={e=>setMsg(e.target.value)} rows={5} placeholder={t('Write your message clearly...','अपना संदेश स्पष्ट रूप से लिखें...')} style={inp}/>
          <button onClick={()=>sendTicket(tab)} disabled={submit} className="btn-p" style={{marginTop:13,width:'100%',opacity:submit?.7:1}}>
            {submit?'⟳ Submitting...':t('Submit','सबमिट करें')}
          </button>
        </div>
      )}
    </div>
  )
}

export default function SupportPage() {
  return <StudentShell pageKey="support"><SupportContent/></StudentShell>
}
