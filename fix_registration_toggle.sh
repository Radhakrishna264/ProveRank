#!/bin/bash
node << 'NODEOF'
const fs = require('fs')
const candidates = ['/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx','/home/runner/workspace/frontend/src/app/admin/x7k2p/page.tsx']
const path = candidates.find(p => fs.existsSync(p))
if (!path) { console.log('❌ Admin page not found'); process.exit(1) }
console.log('Found:', path)
let code = fs.readFileSync(path, 'utf8')
if (!code.includes('open_registration')) {
  code = code.replace('const DEF_FEATURES: Feature[] = [',`const DEF_FEATURES: Feature[] = [\n  {key:'open_registration',label:'🔓 Student Registration',description:'Allow new student registrations. Toggle OFF to close (Superadmin only)',enabled:true},`)
  console.log('✅ open_registration added to DEF_FEATURES')
}
code = code.replace(
  `    try{await fetch(\`\${API}/api/admin/features\`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:\`Bearer \${token}\`},body:JSON.stringify({key,enabled:ne})})}catch{}`,
  `    if(key==='open_registration'){try{const r=await fetch(\`\${API}/api/auth/admin/registration-control\`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:\`Bearer \${token}\`},body:JSON.stringify({enabled:ne})});const d=await r.json();if(r.ok)T(d.message||'Done','s');else{T(d.message||'Failed','e');setFeatures(p=>p.map(f=>f.key===key?{...f,enabled:!ne}:f))}}catch{T('Error','e');setFeatures(p=>p.map(f=>f.key===key?{...f,enabled:!ne}:f))};return}\n    try{await fetch(\`\${API}/api/admin/features\`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:\`Bearer \${token}\`},body:JSON.stringify({key,enabled:ne})})}catch{}`
)
fs.writeFileSync(path, code, 'utf8')
console.log('✅ toggleFeat patched')
console.log('open_registration present:', code.includes('open_registration') ? 'YES ✅' : 'NO ❌')
NODEOF
cd /home/runner/workspace
git add -A
git commit -m "feat: Registration ON/OFF toggle (Superadmin) in Feature Flags"
git push origin main
echo "✅ Done — Login as Superadmin → Admin Panel → Feature Flags → Student Registration toggle"
