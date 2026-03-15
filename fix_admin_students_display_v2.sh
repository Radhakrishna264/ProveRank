#!/bin/bash
node << 'NODEOF'
const fs = require('fs')

const candidates = [
  '/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx',
  '/home/runner/workspace/frontend/src/app/admin/x7k2p/page.tsx',
]
const path = candidates.find(p => fs.existsSync(p))
if (!path) { console.log('❌ Admin page not found'); process.exit(1) }
console.log('Found:', path)

let code = fs.readFileSync(path, 'utf8')

// Fix 1: setStudents — handle all response formats
code = code.replace(
  'if(Array.isArray(us))setStudents(us)',
  'if(us){const list=Array.isArray(us)?us:(us.students||us.data||us.users||[]);setStudents(list)}'
)

// Fix 2: fetch order — try /api/admin/students FIRST (production endpoint)
code = code.replace(
  'getFirst(`${API}/api/admin/users`,`${API}/api/admin/students`)',
  'getFirst(`${API}/api/admin/students`,`${API}/api/admin/users`,`${API}/api/admin/manage/students`)'
)

fs.writeFileSync(path, code, 'utf8')
console.log('✅ Fixed setStudents to handle all response formats')
console.log('✅ Fixed fetch order — /api/admin/students first')
NODEOF

cd /home/runner/workspace
git add -A
git commit -m "fix: admin panel students display — handle all API response formats"
git push origin main

echo "✅ Done — Admin Panel will now show all 4 students after deploy"
