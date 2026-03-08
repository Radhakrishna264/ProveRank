"use client";
import { useEffect, useState } from "react";
import { getTheme, setTheme } from "@/lib/theme";
export default function ThemeToggle() {
  const [dark, setDark] = useState(true);
  useEffect(()=>{ setDark(getTheme()==="dark"); },[]);
  function toggle(){ const next=dark?"light":"dark"; setTheme(next); setDark(!dark); }
  return (
    <button onClick={toggle} className="flex items-center gap-2 transition" style={{color:"#9CA3AF"}}>
      <span>{dark?"🌙":"☀️"}</span>
      <div className="w-8 h-4 rounded-full relative" style={{background:"#002D55"}}>
        <div className="absolute top-0.5 w-3 h-3 rounded-full transition-all" style={{background:"#4D9FFF",right:dark?"2px":"auto",left:dark?"auto":"2px"}}/>
      </div>
      <span className="text-xs">{dark?"Dark":"Light"}</span>
    </button>
  );
}
