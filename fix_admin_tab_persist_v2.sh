#!/bin/bash
# Fix: Admin panel tab persists on mobile pull-to-refresh
node << 'NODEOF'
const fs = require('fs')
const path = '/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx'
if (!fs.existsSync(path)) { console.log('❌ Not found'); process.exit(1) }

let code = fs.readFileSync(path, 'utf8')

// Fix 1: useState('dashboard') → read from localStorage on init
code = code.replace(
  `const [tab,setTab]=useState('dashboard')`,
  `const [tab,setTab]=useState(()=>{ try{ return localStorage.getItem('pr_admin_tab')||'dashboard' }catch{ return 'dashboard' } })`
)

// Fix 2: wrap setTab to also save to localStorage
code = code.replace(
  `const [tab,setTab]=useState(()=>{ try{ return localStorage.getItem('pr_admin_tab')||'dashboard' }catch{ return 'dashboard' } })`,
  `const [_tab,_setTab]=useState(()=>{ try{ return localStorage.getItem('pr_admin_tab')||'dashboard' }catch{ return 'dashboard' } })
  const tab=_tab
  const setTab=(t:string)=>{ try{localStorage.setItem('pr_admin_tab',t)}catch{} ; _setTab(t) }`
)

fs.writeFileSync(path, code, 'utf8')

// Verify
const v = fs.readFileSync(path, 'utf8')
console.log('pr_admin_tab present:', v.includes('pr_admin_tab') ? 'YES ✅' : 'NO ❌')
console.log('localStorage.setItem present:', v.includes("localStorage.setItem('pr_admin_tab") ? 'YES ✅' : 'NO ❌')
NODEOF

cd /home/runner/workspace
git add -A
git commit -m "fix: admin panel tab persists on refresh via localStorage (mobile pull-to-refresh fix)"
git push origin main
echo "✅ Done — refresh pe same tab pe rahega"
