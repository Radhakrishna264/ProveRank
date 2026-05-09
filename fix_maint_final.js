const fs = require('fs'), path = require('path')
const SHELL = path.join(process.env.HOME, 'workspace/frontend/src/components/StudentShell.tsx')
let code = fs.readFileSync(SHELL, 'utf8')

// useEffect( directly dhundo (import mein sirf useEffect, hai — bracket nahi)
let idx = code.indexOf('useEffect(')
if(idx === -1) idx = code.indexOf('useEffect (')

if(idx === -1){
  console.log('❌ useEffect( not found')
  process.exit(1)
}
console.log('✅ Found useEffect( at index:', idx)
console.log('Context:', code.substring(idx-30, idx+80))

// Maintenance check inject karo PEHLE
const MAINT = `useEffect(()=>{
    fetch('https://proverank.onrender.com/api/admin/maintenance')
      .then(function(r){return r.ok?r.json():null})
      .then(function(d){
        if(d && d.enabled===true){
          var msg=d.message||'We are upgrading the platform. Please check back shortly.'
          document.body.style.cssText='margin:0;padding:0;background:#0a0a1a'
          var wrap=document.createElement('div')
          wrap.style.cssText='min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;background:linear-gradient(135deg,#0a0a1a,#0d1b2a);color:#fff;font-family:Inter,sans-serif;text-align:center;padding:24px'
          wrap.innerHTML='<div style="font-size:60px;margin-bottom:20px">🔧</div>'+'<div style="font-size:24px;font-weight:700;color:#4d9fff;margin-bottom:10px">ProveRank</div>'+'<div style="font-size:18px;font-weight:600;margin-bottom:14px">Platform Under Maintenance</div>'+'<div style="color:#aaa;max-width:360px;line-height:1.7;font-size:14px;margin-bottom:32px">'+msg+'</div>'
          var btn=document.createElement('button')
          btn.innerHTML='&#8592; Back to Login'
          btn.style.cssText='background:linear-gradient(135deg,#4d9fff,#0066cc);color:#fff;border:none;border-radius:10px;padding:13px 32px;font-size:15px;font-weight:700;cursor:pointer;letter-spacing:0.5px'
          btn.onclick=function(){localStorage.removeItem('pr_token');localStorage.removeItem('pr_role');window.location.href='/login'}
          wrap.appendChild(btn)
          document.body.innerHTML=''
          document.body.appendChild(wrap)
        }
      }).catch(function(){})
  },[])

  `

code = code.slice(0, idx) + MAINT + code.slice(idx)
fs.writeFileSync(SHELL, code)
console.log('✅ Maintenance check injected!')
console.log('Logout button:', fs.readFileSync(SHELL,'utf8').includes('Back to Login') ? '✅ YES' : '❌ NO')
