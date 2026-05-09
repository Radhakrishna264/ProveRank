const fs = require('fs')
const path = require('path')

const FILE = path.join(process.env.HOME, 'workspace/frontend/app/admin/x7k2p/page.tsx')
let code = fs.readFileSync(FILE, 'utf8')

// Step 1: Destructuring mein mn add karo
code = code.replace(
  'const [us,ex,qs,st,fl,al,tk,sn,ft,nf,bt,au,rs]=await Promise.all([',
  'const [us,ex,qs,st,fl,al,tk,sn,ft,nf,bt,au,rs,mn]=await Promise.all(['
)

// Step 2: Promise.all array mein maintenance fetch add karo
code = code.replace(
  "getFirst(`${API}/api/results`,`${API}/api/admin/results`),",
  "getFirst(`${API}/api/results`,`${API}/api/admin/results`),\n      get(`${API}/api/admin/maintenance`),"
)

// Step 3: fetchAll ke andar result apply karo
code = code.replace(
  'if(ft){',
  'if(mn!=null) setMainOn(mn.enabled??mn.isEnabled??mn.maintenance??false)\n    if(ft){'
)

fs.writeFileSync(FILE, code)
console.log('✅ Maintenance fix applied successfully!')

// Verify
if(code.includes('mn!=null') && code.includes('api/admin/maintenance') && code.includes('rs,mn]')){
  console.log('✅ All 3 changes verified in file')
} else {
  console.log('❌ Verify failed — check manually')
}
