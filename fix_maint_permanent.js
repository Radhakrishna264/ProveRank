const fs = require('fs'), path = require('path')
const FILE = path.join(process.env.HOME, 'workspace/frontend/app/admin/x7k2p/page.tsx')
let code = fs.readFileSync(FILE, 'utf8')

// 1. useState(false) → localStorage se initialize
code = code.replace(
  'const [mainOn,setMainOn]=useState(false)',
  "const [mainOn,setMainOn]=useState(()=>{try{return localStorage.getItem('pr_maint')==='1'}catch{return false}})"
)

// 2. fetchAll mein backend se aane par localStorage bhi update karo
code = code.replace(
  'setMainOn(mn && mn.enabled===true ? true : false)',
  "if(mn!=null){const s=mn.enabled===true;setMainOn(s);try{localStorage.setItem('pr_maint',s?'1':'0')}catch{}}"
)

// 3. toggleMaint mein localStorage save karo
code = code.replace(
  'const nm=!mainOn\n    setMainOn(nm)',
  "const nm=!mainOn\n    setMainOn(nm)\n    try{localStorage.setItem('pr_maint',nm?'1':'0')}catch{}"
)

fs.writeFileSync(FILE, code)
const v = fs.readFileSync(FILE,'utf8')
console.log('localStorage init:', v.includes("pr_maint)==='1'") ? '✅' : '❌')
console.log('localStorage save on toggle:', v.includes("localStorage.setItem('pr_maint',nm") ? '✅' : '❌')
console.log('localStorage sync from API:', v.includes("localStorage.setItem('pr_maint',s") ? '✅' : '❌')
