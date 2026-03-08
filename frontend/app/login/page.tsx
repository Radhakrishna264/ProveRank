"use client";
import { useState } from "react";
import Link from "next/link";
import ParticlesBg from "@/components/ParticlesBg";
import { getTheme, setTheme } from "@/lib/theme";

export default function LoginPage() {
  const [lang, setLang] = useState<"hi"|"en">("hi");
  const [email, setEmail] = useState("");
  const [pass, setPass] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [theme, setThemeState] = useState<string>(
    typeof window !== "undefined" ? getTheme() : "dark"
  );

  const toggleTheme = () => {
    const next = theme === "dark" ? "light" : "dark";
    setTheme(next); setThemeState(next);
    document.documentElement.classList.toggle("dark", next === "dark");
  };

  const t = lang === "hi" ? {
    title:"ProveRank में स्वागत है", sub:"अपने खाते में लॉगिन करें",
    email:"ईमेल / रोल नंबर", password:"पासवर्ड", btn:"लॉगिन →",
    reg:"नया खाता बनाएं", forgot:"पासवर्ड भूल गए?"
  } : {
    title:"Welcome to ProveRank", sub:"Login to your account",
    email:"Email / Roll Number", password:"Password", btn:"Login →",
    reg:"Create new account", forgot:"Forgot password?"
  };

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault(); setLoading(true); setError("");
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/auth/login`,
        {method:"POST",headers:{"Content-Type":"application/json"},
        body:JSON.stringify({email,password:pass})});
      const data = await res.json();
      if (!res.ok) throw new Error(data.message||"Login failed");
      localStorage.setItem("pr_token", data.token);
      localStorage.setItem("pr_role", data.role);
      window.location.href = data.role==="student"?"/dashboard":
        data.role==="admin"?"/admin":"/superadmin";
    } catch(err:unknown){ setError(err instanceof Error?err.message:"Login failed"); }
    finally{ setLoading(false); }
  }

  return (
    <main className="min-h-screen flex items-center justify-center relative overflow-hidden"
      style={{background:"#000A18"}}>
      <ParticlesBg />

      {/* Theme + Lang toggles */}
      <div className="fixed top-4 right-4 flex gap-2 z-50">
        <button onClick={() => setLang(lang==="hi"?"en":"hi")}
          className="text-xs px-3 py-1 rounded-full border"
          style={{borderColor:"#002D55",color:"#4D9FFF",background:"rgba(0,22,40,0.8)"}}>
          {lang==="hi"?"EN":"हि"}
        </button>
        <button onClick={toggleTheme}
          className="text-xs px-3 py-1 rounded-full border"
          style={{borderColor:"#002D55",color:"#4D9FFF",background:"rgba(0,22,40,0.8)"}}>
          {theme==="dark"?"☀️":"🌙"}
        </button>
      </div>

      {/* Glass Card */}
      <div className="relative z-10 w-full max-w-md mx-4">
        <div className="text-center mb-8">
          <div className="text-2xl mb-2" style={{color:"#4D9FFF"}}>⬡</div>
          <h1 className="text-3xl font-bold mb-1"
            style={{fontFamily:"Georgia,serif",color:"#E8F4FF"}}>{t.title}</h1>
          <p className="text-sm mt-1" style={{color:"#9CA3AF"}}>{t.sub}</p>
        </div>

        <div className="rounded-2xl p-8"
          style={{background:"rgba(255,255,255,0.05)",border:"1px solid #002D55",
          backdropFilter:"blur(12px)",boxShadow:"0 0 40px #4D9FFF22"}}>

          {error && <div className="mb-4 px-4 py-3 rounded-lg text-sm"
            style={{background:"rgba(220,38,38,0.2)",color:"#FCA5A5",border:"1px solid rgba(220,38,38,0.4)"}}>
            {error}</div>}

          <form onSubmit={handleSubmit} className="space-y-5">
            <div className="relative">
              <input type="text" value={email}
                onChange={e=>setEmail(e.target.value)}
                placeholder=" " required
                className="peer w-full px-4 pt-5 pb-2 text-sm rounded-xl outline-none transition"
                style={{background:"#000A18",border:"1px solid #002D55",
                color:"#E8F4FF"}}
                onFocus={e=>e.target.style.borderColor="#4D9FFF"}
                onBlur={e=>e.target.style.borderColor="#002D55"}/>
              <label className="absolute left-4 top-2 text-xs transition-all"
                style={{color:"#4D9FFF"}}>{t.email}</label>
            </div>

            <div className="relative">
              <input type="password" value={pass}
                onChange={e=>setPass(e.target.value)}
                placeholder=" " required
                className="peer w-full px-4 pt-5 pb-2 text-sm rounded-xl outline-none transition"
                style={{background:"#000A18",border:"1px solid #002D55",color:"#E8F4FF"}}
                onFocus={e=>e.target.style.borderColor="#4D9FFF"}
                onBlur={e=>e.target.style.borderColor="#002D55"}/>
              <label className="absolute left-4 top-2 text-xs transition-all"
                style={{color:"#4D9FFF"}}>{t.password}</label>
            </div>

            <div className="flex justify-end">
              <Link href="/forgot-password"
                className="text-xs hover:underline"
                style={{color:"#9CA3AF"}}>{t.forgot}</Link>
            </div>

            <button type="submit" disabled={loading}
              className="w-full font-bold py-3 rounded-xl text-white transition"
              style={{background:"linear-gradient(90deg,#4D9FFF,#00CFFF)",
              opacity:loading?0.6:1}}>
              {loading?"Loading...":t.btn}
            </button>
          </form>

          <div className="text-center mt-6">
            <Link href="/register"
              className="text-sm hover:underline"
              style={{color:"#4D9FFF"}}>{t.reg}</Link>
          </div>
        </div>
      </div>
    </main>
  );
}
