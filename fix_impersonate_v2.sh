#!/bin/bash
node << 'NODEOF'
const fs = require('fs')
const candidates = [
  '/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx',
  '/home/runner/workspace/frontend/src/app/admin/x7k2p/page.tsx',
]
const path = candidates.find(p => fs.existsSync(p))
if (!path) { console.log('❌ Not found'); process.exit(1) }

let code = fs.readFileSync(path, 'utf8')

// Fix 1: impersonate() — accept optional id param
code = code.replace(
  `  const impersonate=useCallback(async()=>{
    if(!impId){T('Student ID required.','e');return}`,
  `  const impersonate=useCallback(async(directId?:string)=>{
    const useId=directId||impId
    if(!useId){T('Student ID required.','e');return}
    const impId=useId`
)

// Fix impersonate body to use the local impId variable
code = code.replace(
  'fetch(`${API}/api/admin/manage/impersonate/${impId}`',
  'fetch(`${API}/api/admin/manage/impersonate/${useId}`'
)
code = code.replace(
  "window.open(`/dashboard?impersonate=${impId}`",
  "window.open(`/dashboard?impersonate=${useId}`"
)

// Fix 2: View as Student button — pass id directly
code = code.replace(
  `onClick={()=>{setImpId(selStudent._id);impersonate()}}`,
  `onClick={()=>impersonate(selStudent._id)}`
)

fs.writeFileSync(path, code, 'utf8')
console.log('✅ Impersonate fix applied — View as Student will work now')
NODEOF

cd /home/runner/workspace
git add -A
git commit -m "fix: View as Student (M4) — pass student ID directly, fix race condition"
git push origin main
echo "✅ Done"
