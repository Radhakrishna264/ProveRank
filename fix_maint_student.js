const fs = require('fs'), path = require('path')
const API = 'https://proverank.onrender.com'

// StudentShell dhundo
const possible = [
  'src/components/StudentShell.tsx',
  'components/StudentShell.tsx',
  'src/components/student-shell.tsx'
].map(p => path.join(process.env.HOME, 'workspace/frontend', p))

let FILE = possible.find(p => fs.existsSync(p))
if(!FILE){ console.log('❌ StudentShell not found. Files:'); require('child_process').execSync('find ~/workspace/frontend/src -name "*.tsx" | head -20', {stdio:'inherit'}); process.exit(1) }

console.log('✅ Found:', FILE)
let code = fs.readFileSync(FILE, 'utf8')

const MAINT_CHECK = `
  // ── Maintenance Mode Check ──
  useEffect(()=>{
    fetch('${API}/api/admin/maintenance')
      .then(r=>r.ok?r.json():null)
      .then(d=>{
        if(d&&(d.enabled||d.maintenance)){
          document.body.style.margin='0'
          document.body.innerHTML=\`<div style="min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;background:#0a0a1a;color:#fff;font-family:Inter,sans-serif;text-align:center;padding:20px"><div style="font-size:64px;margin-bottom:24px">🔧</div><div style="font-size:22px;font-weight:700;color:#4d9fff;margin-bottom:12px">ProveRank</div><div style="font-size:17px;font-weight:600;margin-bottom:16px">Platform Under Maintenance</div><div style="color:#aaa;max-width:380px;line-height:1.6">\${d.message||'We are upgrading the platform. Please check back shortly.'}</div><div style="color:#555;font-size:12px;margin-top:28px">If you are an admin, access the panel directly.</div></div>\`
        }
      }).catch(()=>{})
  },[])
`

// 'use client' ke baad ya first useEffect ke pehle inject karo
if(code.includes("useEffect(()=>{")){
  code = code.replace("useEffect(()=>{", MAINT_CHECK + "\n  useEffect(()=>{")
  // Sirf pehle occurrence replace hua — baaki sahi hain
  // Ek hi baar replace hoga kyunki hum string replace use kar rahe hain (first match)
  fs.writeFileSync(FILE, code)
  console.log('✅ Maintenance check added to StudentShell!')
} else {
  console.log('❌ useEffect not found in StudentShell')
}
