"use client";
import { useState } from "react";
import Link from "next/link";
type Step = "form"|"otp"|"done";
export default function RegisterPage() {
  const [step, setStep] = useState<Step>("form");
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [pass, setPass] = useState("");
  const [otp, setOtp] = useState(["","","","","",""]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  async function sendOtp(e: React.FormEvent) {
    e.preventDefault(); setLoading(true); setError("");
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/auth/send-otp`,{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({email})});
      const data = await res.json();
      if (!res.ok) throw new Error(data.message);
      setStep("otp");
    } catch(err:unknown){ setError(err instanceof Error?err.message:"OTP send failed"); }
    finally{ setLoading(false); }
  }
  async function verifyOtp(e: React.FormEvent) {
    e.preventDefault(); setLoading(true); setError("");
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/auth/register`,{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({name,email,phone,password:pass,otp:otp.join("")})});
      const data = await res.json();
      if (!res.ok) throw new Error(data.message);
      localStorage.setItem("pr_token",data.token);
      setStep("done");
      setTimeout(()=>window.location.href="/dashboard",1500);
    } catch(err:unknown){ setError(err instanceof Error?err.message:"Verification failed"); }
    finally{ setLoading(false); }
  }
  function handleOtpInput(val: string, idx: number) {
    if (!/^\d?$/.test(val)) return;
    const next=[...otp]; next[idx]=val; setOtp(next);
    if (val&&idx<5)(document.getElementById(`otp-${idx+1}`) as HTMLInputElement)?.focus();
  }
  const inputStyle={background:"#000A18",border:"1px solid #002D55",color:"#E8F4FF"};
  return (
    <main className="min-h-screen flex items-center justify-center relative overflow-hidden" style={{background:"#000A18"}}>
      <div className="absolute inset-0 opacity-20 pointer-events-none" style={{backgroundImage:"radial-gradient(#4D9FFF 1px,transparent 1px)",backgroundSize:"40px 40px"}}/>
      <div className="relative z-10 w-full max-w-md mx-4">
        <div className="text-center mb-8">
          <div className="text-5xl mb-2" style={{color:"#4D9FFF"}}>⬢</div>
          <h1 className="text-3xl font-bold" style={{fontFamily:"Georgia,serif",color:"#E8F4FF"}}>ProveRank</h1>
          <p className="text-sm mt-1" style={{color:"#9CA3AF"}}>NEET Pattern Test Platform</p>
        </div>
        <div className="rounded-2xl p-8" style={{background:"rgba(255,255,255,0.05)",border:"1px solid #002D55",backdropFilter:"blur(12px)",boxShadow:"0 0 40px #4D9FFF22"}}>
          {step==="form"&&(
            <>
              <h2 className="text-xl font-bold mb-1" style={{fontFamily:"Georgia,serif",color:"#E8F4FF"}}>नया खाता बनाएं</h2>
              <p className="text-sm mb-6" style={{color:"#9CA3AF"}}>Create your ProveRank account</p>
              {error&&<div className="text-sm rounded-lg px-4 py-3 mb-4" style={{background:"rgba(220,38,38,0.2)",border:"1px solid rgba(220,38,38,0.4)",color:"#FCA5A5"}}>{error}</div>}
              <form onSubmit={sendOtp} className="space-y-4">
                {[{label:"पूरा नाम / Full Name",val:name,set:setName,type:"text"},{label:"ईमेल / Email",val:email,set:setEmail,type:"email"},{label:"मोबाइल / Phone",val:phone,set:setPhone,type:"tel"},{label:"पासवर्ड / Password",val:pass,set:setPass,type:"password"}].map(({label,val,set,type})=>(
                  <div key={label} className="relative">
                    <input type={type} value={val} onChange={e=>set(e.target.value)} placeholder=" " required className="w-full rounded-xl px-4 pt-5 pb-2 text-sm outline-none transition" style={inputStyle} onFocus={e=>e.target.style.borderColor="#4D9FFF"} onBlur={e=>e.target.style.borderColor="#002D55"}/>
                    <label className="absolute left-4 top-2 text-xs" style={{color:"#4D9FFF"}}>{label}</label>
                  </div>
                ))}
                <p className="text-xs" style={{color:"#9CA3AF"}}>Register karne se aap hamari <Link href="/terms" style={{color:"#4D9FFF"}}>Terms & Conditions</Link> se agree karte hain.</p>
                <button type="submit" disabled={loading} className="w-full font-bold py-3 rounded-xl text-white transition disabled:opacity-50" style={{background:"linear-gradient(90deg,#4D9FFF,#00CFFF)"}}>
                  {loading?"Sending OTP...":"OTP भेजें / Send OTP →"}
                </button>
              </form>
              <div className="text-center mt-4"><Link href="/login" className="text-sm hover:underline" style={{color:"#4D9FFF"}}>Already have account? Login →</Link></div>
            </>
          )}
          {step==="otp"&&(
            <>
              <h2 className="text-xl font-bold mb-1" style={{fontFamily:"Georgia,serif",color:"#E8F4FF"}}>OTP Verify करें</h2>
              <p className="text-sm mb-2" style={{color:"#9CA3AF"}}>6-digit OTP bheja gaya hai</p>
              <p className="text-sm font-bold mb-6" style={{color:"#4D9FFF"}}>{email}</p>
              {error&&<div className="text-sm rounded-lg px-4 py-3 mb-4" style={{background:"rgba(220,38,38,0.2)",border:"1px solid rgba(220,38,38,0.4)",color:"#FCA5A5"}}>{error}</div>}
              <form onSubmit={verifyOtp}>
                <div className="flex gap-3 justify-center mb-6">
                  {otp.map((digit,i)=>(
                    <input key={i} id={`otp-${i}`} type="text" maxLength={1} value={digit} onChange={e=>handleOtpInput(e.target.value,i)} className="w-11 h-12 text-center rounded-xl font-bold text-xl outline-none transition" style={{background:"#000A18",border:"2px solid #002D55",color:"#4D9FFF"}} onFocus={e=>e.target.style.borderColor="#4D9FFF"} onBlur={e=>e.target.style.borderColor="#002D55"}/>
                  ))}
                </div>
                <button type="submit" disabled={loading||otp.join("").length<6} className="w-full font-bold py-3 rounded-xl text-white transition disabled:opacity-50" style={{background:"linear-gradient(90deg,#4D9FFF,#00CFFF)"}}>
                  {loading?"Verifying...":"✓ Verify & Register"}
                </button>
              </form>
              <button onClick={()=>setStep("form")} className="w-full text-center text-sm mt-3 hover:underline" style={{color:"#9CA3AF"}}>← Wapas jao</button>
            </>
          )}
          {step==="done"&&(
            <div className="text-center py-8">
              <div className="text-5xl mb-4">✅</div>
              <h2 className="text-xl font-bold" style={{fontFamily:"Georgia,serif",color:"#E8F4FF"}}>Registration Complete!</h2>
              <p className="text-sm mt-2" style={{color:"#9CA3AF"}}>Dashboard pe redirect ho raha hai...</p>
            </div>
          )}
        </div>
      </div>
    </main>
  );
}
