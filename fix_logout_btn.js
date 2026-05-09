const fs = require('fs'), path = require('path')
const SHELL = path.join(process.env.HOME, 'workspace/frontend/src/components/StudentShell.tsx')
let code = fs.readFileSync(SHELL, 'utf8')

// Find exact useEffect pattern (with or without spaces)
const patterns = ['useEffect(()=>{', 'useEffect(() => {', 'useEffect(()=> {', 'useEffect(() =>{']
let found = patterns.find(p => code.includes(p))

if(!found){ console.log('❌ No useEffect found. First 200 chars:'); console.log(code.substring(0,200)); process.exit(1) }
console.log('✅ Found pattern:', found)

const MAINT = `
  // S66 Maintenance Check
  useEffect(()=>{
    fetch('https://proverank.onrender.com/api/admin/maintenance')
      .then(r=>r.ok?r.json():null)
      .then(function(d){
        if(d && d.enabled===true){
          var msg=d.message||'We are upgrading the platform. Please check back shortly.'
          document.body.style.cssText='margin:0;padding:0;background:#0a0a1a'
          var div=document.createElement('div')
          div.style.cssText='min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;background:linear-gradient(135deg,#0a0a1a,#0d1b2a);color:#fff;font-family:Inter,sans-serif;text-align:center;padding:24px'
          div.innerHTML='<div style="font-size:60px;margin-bottom:20px">🔧</div><div style="font-size:24px;font-weight:700;color:#4d9fff;margin-bottom:10px">ProveRank</div><div style="font-size:18px;font-weight:600;margin-bottom:14px">Platform Under Maintenance</div><div style="color:#aaa;max-width:360px;line-height:1.7;font-size:14px;margin-bottom:32px">'+msg+'</div>'
          var btn=document.createElement('button')
          btn.textContent='Back to Login'
          btn.style.cssText='background:linear-gradient(135deg,#4d9fff,#0066cc);color:#fff;border:none;border-radius:10px;padding:13px 32px;font-size:15px;font-weight:700;cursor:pointer'
          btn.onclick=function(){localStorage.removeItem('pr_token');localStorage.removeItem('pr_role');window.location.href='/login'}
          div.appendChild(btn)
          document.body.innerHTML=''
          document.body.appendChild(div)
        }
      }).catch(function(){})
  },[])
`

code = code.replace(found, MAINT + '\n\n  ' + found)
fs.writeFileSync(SHELL, code)

const verify = fs.readFileSync(SHELL,'utf8')
console.log('Logout onclick present:', verify.includes("href='/login'") ? '✅ YES' : '❌ NO')
console.log('S66 comment present:', verify.includes('S66 Maintenance Check') ? '✅ YES' : '❌ NO')
