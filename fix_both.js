const fs = require('fs'), path = require('path')
const HOME = process.env.HOME

// ── Fix 1: StudentShell — Logout button + better maintenance HTML ──
const SHELL = path.join(HOME, 'workspace/frontend/src/components/StudentShell.tsx')
let shell = fs.readFileSync(SHELL, 'utf8')

// Purana maintenance check hatao (mera pehla wala)
shell = shell.replace(/\/\/ ── Maintenance Mode Check ──[\s\S]*?\}\)\s*\}\s*\}\s*\},\[\]\)/m, '')

// Naya maintenance check — logout button ke saath
const NEW_CHECK = `
  // ── Maintenance Mode Check (S66) ──
  useEffect(()=>{
    fetch('https://proverank.onrender.com/api/admin/maintenance')
      .then(r=>r.ok?r.json():null)
      .then(d=>{
        if(d && d.enabled===true){
          document.body.style.cssText='margin:0;padding:0'
          document.body.innerHTML=\`
            <div style="min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;background:linear-gradient(135deg,#0a0a1a 0%,#0d1b2a 100%);color:#fff;font-family:Inter,sans-serif;text-align:center;padding:24px">
              <div style="font-size:64px;margin-bottom:20px">🔧</div>
              <div style="font-size:24px;font-weight:700;color:#4d9fff;margin-bottom:10px;letter-spacing:1px">ProveRank</div>
              <div style="font-size:18px;font-weight:600;margin-bottom:14px;color:#fff">Platform Under Maintenance</div>
              <div style="color:#aaa;max-width:360px;line-height:1.7;font-size:14px;margin-bottom:32px">\${d.message||'We are upgrading the platform. Please check back shortly.'}</div>
              <button onclick="localStorage.removeItem('pr_token');localStorage.removeItem('pr_role');window.location.href='/login'" style="background:linear-gradient(135deg,#4d9fff,#0066cc);color:#fff;border:none;border-radius:10px;padding:13px 28px;font-size:15px;font-weight:700;cursor:pointer;letter-spacing:0.5px">← Back to Login</button>
            </div>
          \`
        }
      }).catch(()=>{})
  },[])
`

// First useEffect se pehle inject karo
shell = shell.replace('useEffect(()=>{', NEW_CHECK + '\n  useEffect(()=>{')
fs.writeFileSync(SHELL, shell)
console.log('✅ Fix 1: StudentShell maintenance page updated with logout button!')

// ── Fix 2: Admin page.tsx — Robust OFF state fix ──
const ADMIN = path.join(HOME, 'workspace/frontend/app/admin/x7k2p/page.tsx')
let admin = fs.readFileSync(ADMIN, 'utf8')

// Purana mn fix replace karo with more explicit check
admin = admin.replace(
  'if(mn!=null) setMainOn(mn.enabled??mn.isEnabled??mn.maintenance??false)',
  'setMainOn(mn && mn.enabled===true ? true : false)'
)

fs.writeFileSync(ADMIN, admin)
console.log('✅ Fix 2: Admin maintenance state — explicit boolean check applied!')

// Verify
const a2 = fs.readFileSync(ADMIN, 'utf8')
const s2 = fs.readFileSync(SHELL, 'utf8')
if(a2.includes('mn.enabled===true')) console.log('✅ Admin fix verified')
else console.log('❌ Admin fix NOT found')
if(s2.includes('Back to Login')) console.log('✅ Shell logout button verified')
else console.log('❌ Shell logout button NOT found')
