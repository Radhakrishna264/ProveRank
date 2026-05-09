const fs = require('fs'), path = require('path')
const SHELL = path.join(process.env.HOME, 'workspace/frontend/src/components/StudentShell.tsx')
let code = fs.readFileSync(SHELL, 'utf8')

// Saari purani maintenance check lines hatao
const lines = code.split('\n')
let skip = false, cleaned = []
for(const line of lines){
  if(line.includes('Maintenance Mode Check') || line.includes('Maintenance check')){
    skip = true
  }
  if(skip){
    // Ek complete useEffect block skip karo (],[]) pe band ho)
    if(line.includes('},[])') && line.includes('useEffect')){
      skip = false; continue
    }
    // Sirf useEffect closing line pe skip band karo
    if(line.trim()==='  },[])'){
      skip = false; continue
    }
    continue
  }
  cleaned.push(line)
}
code = cleaned.join('\n')

// Naya maintenance check — logout button ke saath, reliable HTML
const MAINT = `
  // S66 Maintenance Check
  useEffect(()=>{
    fetch('https://proverank.onrender.com/api/admin/maintenance')
      .then(r=>r.ok?r.json():null)
      .then(d=>{
        if(d && d.enabled===true){
          const msg = d.message || 'We are upgrading the platform. Please check back shortly.'
          document.body.style.cssText='margin:0;padding:0;background:#0a0a1a'
          document.body.innerHTML='<div id="maint-wrap" style="min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;background:linear-gradient(135deg,#0a0a1a,#0d1b2a);color:#fff;font-family:Inter,sans-serif;text-align:center;padding:24px"><div style="font-size:60px;margin-bottom:20px">🔧</div><div style="font-size:24px;font-weight:700;color:#4d9fff;margin-bottom:10px">ProveRank</div><div style="font-size:18px;font-weight:600;margin-bottom:14px">Platform Under Maintenance</div><div style="color:#aaa;max-width:360px;line-height:1.7;font-size:14px;margin-bottom:32px">'+msg+'</div><button id="maint-logout" style="background:linear-gradient(135deg,#4d9fff,#0066cc);color:#fff;border:none;border-radius:10px;padding:13px 32px;font-size:15px;font-weight:700;cursor:pointer">← Back to Login</button></div>'
          document.getElementById('maint-logout').addEventListener('click',function(){
            localStorage.removeItem('pr_token')
            localStorage.removeItem('pr_role')
            window.location.href='/login'
          })
        }
      }).catch(()=>{})
  },[])
`

// Pehle useEffect se pehle inject karo
code = code.replace('useEffect(()=>{', MAINT + '\n  useEffect(()=>{')
fs.writeFileSync(SHELL, code)
console.log('✅ Fix done!')

// Verify
const check = fs.readFileSync(SHELL,'utf8')
console.log('Logout button present:', check.includes('maint-logout') ? '✅ YES' : '❌ NO')
console.log('Admin text removed:', !check.includes('access the panel directly') ? '✅ YES' : '❌ Still there')
