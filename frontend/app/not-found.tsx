"use client";
import Link from "next/link";
import { useEffect, useState } from "react";
export default function NotFound() {
  const [angle, setAngle] = useState(0);
  useEffect(()=>{
    const id=setInterval(()=>setAngle(a=>(a+1)%360),16);
    return ()=>clearInterval(id);
  },[]);
  return (
    <main className="min-h-screen flex flex-col items-center justify-center text-center px-4" style={{background:"#000A18"}}>
      <div style={{transform:`rotate(${angle}deg)`,fontSize:80,color:"#002D55",lineHeight:1}}>⬢</div>
      <h1 className="text-7xl font-black mt-[-10px] mb-2" style={{fontFamily:"Georgia,serif",color:"#4D9FFF"}}>404</h1>
      <p className="text-lg font-bold mb-2" style={{color:"#E8F4FF"}}>Page not found</p>
      <p className="text-sm mb-8" style={{color:"#9CA3AF"}}>Ye URL exist nahi karta. URL check karo.</p>
      <div className="flex gap-4">
        <Link href="/" className="px-6 py-3 rounded-xl text-white font-bold text-sm" style={{background:"linear-gradient(90deg,#4D9FFF,#00CFFF)"}}>🏠 Home</Link>
        <button onClick={()=>window.history.back()} className="px-6 py-3 rounded-xl font-bold text-sm transition" style={{border:"1px solid #4D9FFF",color:"#4D9FFF"}}>← Back</button>
      </div>
    </main>
  );
}
