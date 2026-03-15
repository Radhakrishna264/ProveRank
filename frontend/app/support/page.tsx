'use client'
import { useState } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const C = { primary:'#4D9FFF', card:'rgba(0,22,40,0.80)', border:'rgba(77,159,255,0.22)', text:'#E8F4FF', sub:'#6B8FAF', success:'#00C48C', gold:'#FFD700', danger:'#FF4D4D', warn:'#FFB84D' }

export default function SupportPage() {
  return (
    <StudentShell pageKey="support">
      {({lang, darkMode:dm, user, toast, token}) => {
        const [tab, setTab] = useState<'contact'|'feedback'|'faq'|'grievance'|'challenge'|'reeval'>('contact')
        const [feedbackMsg, setFeedbackMsg] = useState('')
        const [grievanceMsg, setGrievanceMsg] = useState('')
        const [submitting, setSubmitting] = useState(false)
        const [challengeText, setChallengeText] = useState('')
        const [reevalText, setReevalText] = useState('')

        const submitTicket = async (type:string, message:string) => {
          if(!message.trim()){toast(lang==='en'?'Please write a message':'कृपया एक संदेश लिखें','e');return}
          setSubmitting(true)
          try {
            const res = await fetch(`${API}/api/support/ticket`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({type,message,studentName:user?.name,studentEmail:user?.email})})
            if(res.ok){toast(lang==='en'?'Submitted successfully! We will respond within 48 hours.':'सफलतापूर्वक सबमिट किया! हम 48 घंटों में जवाब देंगे।','s');setFeedbackMsg('');setGrievanceMsg('');setChallengeText('');setReevalText('')}
            else toast(lang==='en'?'Failed to submit. Try again.':'सबमिट नहीं हुआ। पुनः प्रयास करें।','e')
          } catch{toast('Network error','e')}
          setSubmitting(false)
        }

        const faqs = [
          {q:lang==='en'?'How to start an exam?':'परीक्षा कैसे शुरू करें?',a:lang==='en'?'Go to My Exams → click Start Exam. Ensure webcam is allowed and internet is stable.':'मेरी परीक्षाएं पर जाएं → परीक्षा शुरू करें पर क्लिक करें।'},
          {q:lang==='en'?'My exam was auto-submitted. What happened?':'मेरी परीक्षा स्वतः सबमिट हो गई। क्यों?',a:lang==='en'?'3 tab-switch warnings trigger auto-submit as per exam rules.':'3 टैब-स्विच चेतावनियों पर परीक्षा नियमानुसार स्वतः सबमिट होती है।'},
          {q:lang==='en'?'How to challenge an answer key?':'उत्तर कुंजी को कैसे चुनौती दें?',a:lang==='en'?'Go to Support → Answer Challenge tab and submit your objection with reasoning.':'Support → Answer Challenge tab पर जाएं और कारण के साथ आपत्ति सबमिट करें।'},
          {q:lang==='en'?'When are results published?':'परिणाम कब प्रकाशित होते हैं?',a:lang==='en'?'Results are published within 2-3 hours of exam completion.':'परीक्षा समाप्ति के 2-3 घंटों के भीतर परिणाम प्रकाशित होते हैं।'},
          {q:lang==='en'?'How to download my certificate?':'प्रमाणपत्र कैसे डाउनलोड करें?',a:lang==='en'?'Go to Certificates page → select your certificate → Download PDF.':'प्रमाणपत्र पेज पर जाएं → अपना प्रमाणपत्र चुनें → PDF डाउनलोड करें।'},
        ]

        const inp:any={width:'100%',padding:'12px 14px',background:'rgba(0,22,40,0.85)',border:`1.5px solid rgba(77,159,255,0.3)`,borderRadius:10,color:C.text,fontSize:13,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box'}

        return (
          <div style={{animation:'fadeIn .4s ease'}}>
            <div style={{marginBottom:20}}>
              <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>{lang==='en'?'Support & Feedback':'सहायता और प्रतिक्रिया'}</h1>
              <div style={{fontSize:13,color:C.sub}}>{lang==='en'?'We value your feedback. Help us improve ProveRank.':'हम आपकी प्रतिक्रिया को महत्व देते हैं। ProveRank को बेहतर बनाने में मदद करें।'}</div>
            </div>

            {/* SVG Banner */}
            <div style={{background:'linear-gradient(135deg,rgba(0,196,140,0.08),rgba(0,22,40,0.85))',border:`1px solid rgba(0,196,140,0.2)`,borderRadius:20,padding:'20px',marginBottom:24,display:'flex',alignItems:'center',gap:16,position:'relative',overflow:'hidden'}}>
              <div style={{position:'absolute',right:16,top:'50%',transform:'translateY(-50%)',opacity:.08}}>
                <svg width="120" height="100" viewBox="0 0 120 100" fill="none">
                  <path d="M20 30 Q20 15 35 15 L85 15 Q100 15 100 30 L100 60 Q100 75 85 75 L60 75 L40 90 L40 75 L35 75 Q20 75 20 60 Z" stroke="#00C48C" strokeWidth="2" fill="none"/>
                  <circle cx="45" cy="45" r="4" fill="#00C48C"/>
                  <circle cx="60" cy="45" r="4" fill="#00C48C"/>
                  <circle cx="75" cy="45" r="4" fill="#00C48C"/>
                </svg>
              </div>
              <span style={{fontSize:30}}>🛟</span>
              <div style={{flex:1}}>
                <div style={{fontSize:14,color:C.success,fontStyle:'italic',fontWeight:700,marginBottom:3}}>{lang==='en'?'"We are here for you — every question deserves an answer."':'"हम आपके लिए यहां हैं — हर सवाल का जवाब मिलेगा।"'}</div>
                <div style={{fontSize:11,color:C.sub}}>{lang==='en'?'Response time: Technical issues < 12 hrs | General queries 2-3 days':'प्रतिक्रिया समय: तकनीकी < 12 घंटे | सामान्य 2-3 दिन'}</div>
              </div>
            </div>

            {/* Tabs */}
            <div style={{display:'flex',gap:6,marginBottom:20,flexWrap:'wrap'}}>
              {[['contact','📞',lang==='en'?'Contact':'संपर्क'],['feedback','💬',lang==='en'?'Feedback':'प्रतिक्रिया'],['faq','❓',lang==='en'?'FAQ':'FAQ'],['grievance','🎫',lang==='en'?'Grievance':'शिकायत'],['challenge','⚔️',lang==='en'?'Answer Key':'उत्तर कुंजी'],['reeval','🔄',lang==='en'?'Re-Evaluation':'पुनर्मूल्यांकन']].map(([id,ic,label])=>(
                <button key={id} onClick={()=>setTab(id as any)} style={{padding:'8px 14px',borderRadius:10,border:`1px solid ${tab===id?C.primary:C.border}`,background:tab===id?`${C.primary}22`:C.card,color:tab===id?C.primary:C.sub,cursor:'pointer',fontSize:11,fontWeight:tab===id?700:400,fontFamily:'Inter,sans-serif'}}>
                  {ic} {label}
                </button>
              ))}
            </div>

            {/* Contact Tab */}
            {tab==='contact'&&(
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:16}}>
                {[{icon:'📧',title:lang==='en'?'Email Support':'ईमेल सहायता',val:'support@proverank.com',sub:lang==='en'?'Response within 24-48 hours':'24-48 घंटों में जवाब',col:C.primary},{icon:'⚡',title:lang==='en'?'Technical Issues':'तकनीकी समस्याएं',val:`< 12 ${lang==='en'?'hours':'घंटे'}`,sub:lang==='en'?'Critical bug response time':'गंभीर बग प्रतिक्रिया समय',col:C.danger},{icon:'📋',title:lang==='en'?'Exam Grievances':'परीक्षा शिकायतें',val:`< 48 ${lang==='en'?'hours':'घंटे'}`,sub:lang==='en'?'Result and marking disputes':'परिणाम और अंकन विवाद',col:C.warn},{icon:'💡',title:lang==='en'?'General Queries':'सामान्य प्रश्न',val:`2-3 ${lang==='en'?'days':'दिन'}`,sub:lang==='en'?'Platform usage, features':'प्लेटफ़ॉर्म उपयोग, सुविधाएं',col:C.success}].map((c,i)=>(
                  <div key={i} className="card-h" style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:20,backdropFilter:'blur(12px)',transition:'all .2s'}}>
                    <div style={{fontSize:28,marginBottom:10}}>{c.icon}</div>
                    <div style={{fontWeight:700,fontSize:14,color:dm?C.text:'#0F172A',marginBottom:4}}>{c.title}</div>
                    <div style={{fontWeight:700,fontSize:16,color:c.col,marginBottom:4}}>{c.val}</div>
                    <div style={{fontSize:11,color:C.sub}}>{c.sub}</div>
                  </div>
                ))}
                <div style={{gridColumn:'1/-1',background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:20,backdropFilter:'blur(12px)'}}>
                  <div style={{fontWeight:700,fontSize:13,color:dm?C.text:'#0F172A',marginBottom:12}}>🔗 {lang==='en'?'Quick Links':'त्वरित लिंक'}</div>
                  <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8}}>
                    {[['⚔️',lang==='en'?'Answer Key Challenge':'उत्तर कुंजी चुनौती','challenge'],['🔄',lang==='en'?'Re-evaluation Request':'पुनर्मूल्यांकन अनुरोध','reeval'],['🎫',lang==='en'?'Grievance / Complaint':'शिकायत','grievance'],['👤',lang==='en'?'Account Issues':'अकाउंट समस्याएं','contact']].map(([ic,label,t2])=>(
                      <button key={String(label)} onClick={()=>setTab(t2 as any)} style={{display:'flex',alignItems:'center',gap:8,padding:'10px 14px',background:'rgba(77,159,255,0.07)',border:`1px solid ${C.border}`,borderRadius:10,cursor:'pointer',textAlign:'left',fontFamily:'Inter,sans-serif',fontSize:12,color:dm?C.text:'#0F172A',fontWeight:600}}>
                        <span>{ic}</span><span>{label}</span>
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* Feedback Tab */}
            {tab==='feedback'&&(
              <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:24,backdropFilter:'blur(12px)'}}>
                <div style={{fontWeight:700,fontSize:15,color:dm?C.text:'#0F172A',marginBottom:16}}>💬 {lang==='en'?'Share Your Feedback':'अपनी प्रतिक्रिया शेयर करें'}</div>
                <textarea value={feedbackMsg} onChange={e=>setFeedbackMsg(e.target.value)} rows={5} placeholder={lang==='en'?'Write your feedback, suggestions, or comments here...':'यहां अपनी प्रतिक्रिया, सुझाव या टिप्पणियां लिखें...'} style={{...inp,resize:'vertical'}}/>
                <button onClick={()=>submitTicket('feedback',feedbackMsg)} disabled={submitting} className="btn-p" style={{marginTop:14,opacity:submitting?.7:1}}>
                  {submitting?'⟳ Submitting...':lang==='en'?'Submit Feedback':'प्रतिक्रिया सबमिट करें'}
                </button>
              </div>
            )}

            {/* FAQ Tab */}
            {tab==='faq'&&(
              <div>
                {faqs.map((faq,i)=>(
                  <details key={i} style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:12,marginBottom:8,overflow:'hidden',backdropFilter:'blur(12px)'}}>
                    <summary style={{padding:'14px 18px',cursor:'pointer',fontWeight:600,fontSize:13,color:dm?C.text:'#0F172A',listStyle:'none',display:'flex',justifyContent:'space-between',alignItems:'center'}}>
                      <span>❓ {faq.q}</span><span style={{color:C.primary}}>▾</span>
                    </summary>
                    <div style={{padding:'0 18px 14px',fontSize:12,color:C.sub,lineHeight:1.7,borderTop:`1px solid ${C.border}`}}>{faq.a}</div>
                  </details>
                ))}
              </div>
            )}

            {/* Grievance Tab */}
            {tab==='grievance'&&(
              <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:24,backdropFilter:'blur(12px)'}}>
                <div style={{fontWeight:700,fontSize:15,color:dm?C.text:'#0F172A',marginBottom:6}}>🎫 {lang==='en'?'File a Grievance (S92)':'शिकायत दर्ज करें'}</div>
                <div style={{fontSize:12,color:C.sub,marginBottom:16}}>{lang==='en'?'Formal complaint — Open/In Progress/Resolved status tracked':'औपचारिक शिकायत — स्थिति ट्रैक की जाती है'}</div>
                <textarea value={grievanceMsg} onChange={e=>setGrievanceMsg(e.target.value)} rows={5} placeholder={lang==='en'?'Describe your grievance in detail...':'अपनी शिकायत विस्तार से लिखें...'} style={{...inp,resize:'vertical'}}/>
                <button onClick={()=>submitTicket('grievance',grievanceMsg)} disabled={submitting} className="btn-p" style={{marginTop:14,width:'100%',opacity:submitting?.7:1}}>
                  {submitting?'⟳ Submitting...':lang==='en'?'Submit Grievance':'शिकायत सबमिट करें'}
                </button>
              </div>
            )}

            {/* Answer Challenge Tab */}
            {tab==='challenge'&&(
              <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:24,backdropFilter:'blur(12px)'}}>
                <div style={{fontWeight:700,fontSize:15,color:dm?C.text:'#0F172A',marginBottom:6}}>⚔️ {lang==='en'?'Answer Key Challenge (S69)':'उत्तर कुंजी चुनौती'}</div>
                <div style={{fontSize:12,color:C.sub,marginBottom:16}}>{lang==='en'?'Disagree with the official answer? Submit your objection with proper reasoning.':'आधिकारिक उत्तर से असहमत हैं? उचित तर्क के साथ आपत्ति सबमिट करें।'}</div>
                <textarea value={challengeText} onChange={e=>setChallengeText(e.target.value)} rows={5} placeholder={lang==='en'?'Mention: Exam name, Question number, Your answer, Reasoning/Source...':'उल्लेख करें: परीक्षा नाम, प्रश्न संख्या, आपका उत्तर, तर्क/स्रोत...'} style={{...inp,resize:'vertical'}}/>
                <button onClick={()=>submitTicket('answer_challenge',challengeText)} disabled={submitting} className="btn-p" style={{marginTop:14,width:'100%',opacity:submitting?.7:1}}>
                  {submitting?'⟳ Submitting...':lang==='en'?'Submit Challenge':'चुनौती सबमिट करें'}
                </button>
              </div>
            )}

            {/* Re-evaluation Tab */}
            {tab==='reeval'&&(
              <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:24,backdropFilter:'blur(12px)'}}>
                <div style={{fontWeight:700,fontSize:15,color:dm?C.text:'#0F172A',marginBottom:6}}>🔄 {lang==='en'?'Re-Evaluation Request (S71)':'पुनर्मूल्यांकन अनुरोध'}</div>
                <div style={{fontSize:12,color:C.sub,marginBottom:16}}>{lang==='en'?'Request a manual re-check of your answer sheet. Status: Pending/Approved/Rejected.':'आपकी उत्तर पुस्तिका की पुनः जांच का अनुरोध। स्थिति: लंबित/स्वीकृत/अस्वीकृत।'}</div>
                <textarea value={reevalText} onChange={e=>setReevalText(e.target.value)} rows={5} placeholder={lang==='en'?'Mention: Exam name, Question numbers to re-check, Reason for request...':'उल्लेख करें: परीक्षा नाम, पुनः जांच के प्रश्न, अनुरोध का कारण...'} style={{...inp,resize:'vertical'}}/>
                <button onClick={()=>submitTicket('re_eval',reevalText)} disabled={submitting} className="btn-p" style={{marginTop:14,width:'100%',opacity:submitting?.7:1}}>
                  {submitting?'⟳ Submitting...':lang==='en'?'Submit Request':'अनुरोध सबमिट करें'}
                </button>
              </div>
            )}
          </div>
        )
      }}
    </StudentShell>
  )
}
