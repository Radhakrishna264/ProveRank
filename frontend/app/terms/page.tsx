"use client";
import { useState } from "react";
const SECTIONS=[{title:"1. Exam Rules",content:"Exam mein cheating strictly prohibited hai. Webcam on rehna compulsory hai. Tab switching 3 baar se zyada hone par auto-submit ho jayega. Exam start hone ke baad koi change nahi ho sakta."},{title:"2. Privacy Policy",content:"Aapka data secure server pe store hoga. Kisi third party ko share nahi kiya jayega. Proctoring ke liye webcam footage temporarily store hoti hai aur 30 din baad delete ho jati hai."},{title:"3. Proctoring Policy",content:"Webcam compulsory hai. Face detection active rahega. Head movement track hogi. Suspicious activity report admin ko jayegi. 3 violations par exam auto-submit hoga."},{title:"4. Account Terms",content:"Ek student ek account. Account share karna banned hai. Fake account banane par permanent ban ho sakta hai. Admin ka decision final hoga."}];
export default function TermsPage() {
  const [open, setOpen] = useState<number|null>(null);
  const [accepted, setAccepted] = useState(false);
  return (
    <main className="min-h-screen py-12 px-4" style={{background:"#000A18"}}>
      <div className="max-w-2xl mx-auto">
        <div className="text-center mb-8">
          <div className="text-4xl mb-2" style={{color:"#4D9FFF"}}>⬢</div>
          <h1 className="text-2xl font-bold" style={{fontFamily:"Georgia,serif",color:"#E8F4FF"}}>Terms & Conditions</h1>
          <p className="text-sm mt-1" style={{color:"#9CA3AF"}}>ProveRank — NEET Test Platform</p>
        </div>
        <div className="rounded-2xl overflow-hidden mb-6" style={{background:"#001628",border:"1px solid #002D55"}}>
          {SECTIONS.map((sec,i)=>(
            <div key={i} style={{borderBottom:i<SECTIONS.length-1?"1px solid #002D55":"none"}}>
              <button onClick={()=>setOpen(open===i?null:i)} className="w-full flex justify-between items-center px-6 py-4 text-left transition" style={{color:"#E8F4FF"}}>
                <span className="font-bold text-sm">{sec.title}</span>
                <span style={{color:"#4D9FFF"}}>{open===i?"▲":"▼"}</span>
              </button>
              {open===i&&<div className="px-6 py-4 text-sm leading-relaxed" style={{background:"rgba(0,10,24,0.5)",color:"#9CA3AF"}}>{sec.content}</div>}
            </div>
          ))}
        </div>
        <div className="rounded-xl p-5 mb-6" style={{background:"#001628",border:"1px solid #002D55"}}>
          <label className="flex items-start gap-3 cursor-pointer">
            <input type="checkbox" checked={accepted} onChange={e=>setAccepted(e.target.checked)} className="mt-1 w-4 h-4" style={{accentColor:"#4D9FFF"}}/>
            <span className="text-sm" style={{color:"#E8F4FF"}}>Maine ye sab Terms & Conditions padh liye hain aur main inhe accept karta/karti hoon.</span>
          </label>
        </div>
        <button disabled={!accepted} onClick={()=>window.history.back()} className="w-full font-bold py-3 rounded-xl text-white transition disabled:opacity-30 disabled:cursor-not-allowed" style={{background:accepted?"linear-gradient(90deg,#4D9FFF,#00CFFF)":"#002D55"}}>
          {accepted?"✓ Accept & Continue":"Pehle T&C padho"}
        </button>
      </div>
    </main>
  );
}
