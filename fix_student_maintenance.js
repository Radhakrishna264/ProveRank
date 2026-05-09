const fs = require('fs'), path = require('path')
const SHELL = path.join(process.env.HOME, 'workspace/frontend/src/components/StudentShell.tsx')

let code = fs.readFileSync(SHELL, 'utf8')

// Add maintenance check after token check in useEffect
const OLD = `useEffect(()=>{
    const t=localStorage.getItem('pr_token')`

const NEW = `useEffect(()=>{
    // Maintenance check
    fetch('${process.env.NEXT_PUBLIC_API_URL||"https://proverank.onrender.com"}/api/admin/maintenance')
      .then(r=>r.json()).then(d=>{
        if(d.enabled||d.maintenance){
          document.body.innerHTML='<div style="min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;background:#0a0a1a;color:#fff;font-family:Inter,sans-serif;text-align:center;padding:20px"><div style="font-size:60px;margin-bottom:20px">🔧</div><h1 style="font-size:28px;color:#4d9fff;margin-bottom:12px">ProveRank</h1><h2 style="font-size:18px;margin-bottom:16px">Platform is under maintenance</h2><p style="color:#aaa;max-width:400px">'+(d.message||"We'll be back shortly. Thank you for your patience.")+' </p><p style="color:#666;font-size:12px;margin-top:24px">Please check back later.</p></div>'
        }
      }).catch(()=>{})
    const t=localStorage.getItem('pr_token')`

if(code.includes(OLD)){
  code = code.replace(OLD, NEW)
  fs.writeFileSync(SHELL, code)
  console.log('✅ Student maintenance check added!')
} else {
  console.log('❌ Pattern not found — share StudentShell.tsx content')
}
