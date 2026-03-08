export function getTheme():"dark"|"light"{ if(typeof window==="undefined")return "dark"; return(localStorage.getItem("pr_theme") as "dark"|"light")||"dark"; }
export function setTheme(theme:"dark"|"light"){ localStorage.setItem("pr_theme",theme); document.documentElement.classList.toggle("dark",theme==="dark"); }
export function initTheme(){ const t=getTheme(); document.documentElement.classList.toggle("dark",t==="dark"); }
