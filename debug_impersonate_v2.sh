#!/bin/bash
echo "=== IMPERSONATE DIAGNOSTIC ==="

node << 'NODEOF'
const fs = require('fs')

// 1. Check StudentShell — what order is useEffect doing things?
const shellPath = '/home/runner/workspace/frontend/src/components/StudentShell.tsx'
const shell = fs.readFileSync(shellPath, 'utf8')

console.log('\n=== 1. StudentShell useEffect — first 40 lines after useEffect ===')
const effIdx = shell.indexOf('useEffect(()=>{')
const effSlice = shell.substring(effIdx, effIdx+1500)
console.log(effSlice.substring(0,1200))

console.log('\n=== 2. sessionStorage check present? ===')
console.log('imp_token check:', shell.includes("imp_token") ? 'YES ✅' : 'NO ❌')
console.log('sessionStorage.getItem:', shell.includes("sessionStorage.getItem") ? 'YES ✅' : 'NO ❌')

// 2. Check /impersonate page
const impPath = '/home/runner/workspace/frontend/app/impersonate/page.tsx'
if (fs.existsSync(impPath)) {
  console.log('\n=== 3. /impersonate page exists ✅ ===')
  console.log(fs.readFileSync(impPath, 'utf8'))
} else {
  console.log('\n=== 3. /impersonate page MISSING ❌ ===')
}

// 3. Check admin impersonate function
const adminPath = '/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx'
const admin = fs.readFileSync(adminPath, 'utf8')
const impFnIdx = admin.indexOf('impersonate')
console.log('\n=== 4. Admin impersonate function ===')
console.log(admin.substring(impFnIdx, impFnIdx+600))

// 4. Check backend impersonate route
const be = [
  '/home/runner/workspace/src/routes/admin.js',
  '/home/runner/workspace/src/routes/adminRoutes.js',
].find(p => fs.existsSync(p))
if (be) {
  const beCode = fs.readFileSync(be, 'utf8')
  console.log('\n=== 5. Backend impersonate endpoint ===')
  const beIdx = beCode.indexOf('impersonate')
  if (beIdx > -1) console.log(beCode.substring(beIdx, beIdx+400))
  else console.log('❌ NOT FOUND in backend routes')
}
NODEOF

echo ""
echo "=== 6. Test backend impersonate API directly ==="
# Login first
TOKEN=$(curl -s -X POST https://proverank.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@proverank.com","password":"ProveRank@SuperAdmin123"}' \
  | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{ try{console.log(JSON.parse(d).token||'')}catch{console.log('')} })")

if [ -z "$TOKEN" ]; then echo "❌ Login failed"; exit 1; fi
echo "✅ Token OK"

# Get first student ID
STU_ID=$(curl -s https://proverank.onrender.com/api/admin/students \
  -H "Authorization: Bearer $TOKEN" \
  | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{ try{const r=JSON.parse(d);const l=Array.isArray(r)?r:(r.students||[]);console.log(l[0]?._id||'')}catch{console.log('')} })")

echo "First student ID: $STU_ID"

if [ -n "$STU_ID" ]; then
  echo ""
  echo "=== Calling /api/admin/manage/impersonate/$STU_ID ==="
  curl -s -X POST "https://proverank.onrender.com/api/admin/manage/impersonate/$STU_ID" \
    -H "Authorization: Bearer $TOKEN" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{ try{const r=JSON.parse(d);console.log('Response:',JSON.stringify(r,null,2))}catch{console.log('Raw:',d)} })"
fi
