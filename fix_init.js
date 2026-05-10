const fs = require('fs'), path = require('path')
const FILE = path.join(process.env.HOME, 'workspace/frontend/app/admin/x7k2p/page.tsx')
let code = fs.readFileSync(FILE, 'utf8')

// Exact mainOn line dhundo
const lines = code.split('\n')
const mainOnLine = lines.find(l => l.includes('mainOn') && l.includes('useState'))
console.log('Found line:', mainOnLine)

// Regex se replace karo (spaces ko ignore karo)
const fixed = code.replace(
  /const\s+\[mainOn\s*,\s*setMainOn\]\s*=\s*useState\s*\(\s*false\s*\)/,
  "const [mainOn,setMainOn]=useState(()=>{try{return localStorage.getItem('pr_maint')==='1'}catch{return false}})"
)

if(fixed === code){
  console.log('❌ Pattern not matched — showing mainOn context:')
  lines.forEach((l,i)=>{ if(l.includes('mainOn')) console.log(i+1, l.trim()) })
} else {
  fs.writeFileSync(FILE, fixed)
  console.log('✅ localStorage init fixed!')
}
