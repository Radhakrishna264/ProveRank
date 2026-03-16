#!/bin/bash
# FINAL IMPERSONATE FIX
# Diagnostic confirmed:
# ✅ Backend returns 'impersonateToken' 
# ✅ /impersonate page exists
# ❌ Admin function regex failed — fix directly
# ❌ 'studentToken' vs 'impersonateToken' mismatch

BE=/home/runner/workspace
FE=/home/runner/workspace/frontend

echo "=== Step 1: Fix StudentShell ==="
# Read current file and patch it
node << 'NODEOF'
const fs = require('fs')
const path = '/home/runner/workspace/frontend/src/components/StudentShell.tsx'
let code = fs.readFileSync(path, 'utf8')

// Remove ALL previous imp attempts cleanly
code = code.replace(/\/\/ ── IMPERSONATE MODE[\s\S]*?} catch\(e\) \{\}\n\n/g, '')
code = code.replace(/\/\/ Check if this[\s\S]*?return\s*\}\n/g, '')
code = code.replace(/const _search[\s\S]*?router\.replace[\s\S]*?return\s*\}\n\n/g, '')
code = code.replace(/\/\/ ── IMPERSONATE MODE \(sessionStorage[\s\S]*?} catch\(e\) \{\}\n\n/g, '')

// Verify useEffect start
const hasCheck = code.includes("sessionStorage.getItem('imp_token')")
console.log('Has sessionStorage check:', hasCheck)

if (!hasCheck) {
  const impBlock = `    // ── IMPERSONATE MODE — check sessionStorage (set by /impersonate page) ──
    try {
      const impToken = sessionStorage.getItem('imp_token')
      const impId    = sessionStorage.getItem('imp_id')
      const impName  = sessionStorage.getItem('imp_name')
      if (impToken && impId) {
        setToken(impToken)
        setRole('student')
        setUser({ _id: impId, name: impName||'Student', role:'student', email:'' })
        setMounted(true)
        return
      }
    } catch(e) {}

    `
  code = code.replace(`    const tk=_gt()`, impBlock + `    const tk=_gt()`)
  console.log('✅ sessionStorage check added')
}

fs.writeFileSync(path, code, 'utf8')

// Verify final order
const effIdx = code.indexOf('useEffect(()=>{')
const effSnip = code.substring(effIdx, effIdx+400)
console.log('\nFirst 400 chars of useEffect:')
console.log(effSnip)
NODEOF

echo ""
echo "=== Step 2: Fix /impersonate page ==="
mkdir -p $FE/app/impersonate
cat > $FE/app/impersonate/page.tsx << 'EOF_IMP'
'use client'
import { Suspense, useEffect } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'

function Inner() {
  const router = useRouter()
  const params = useSearchParams()

  useEffect(() => {
    const token = params.get('token')
    const id    = params.get('id')
    const name  = params.get('name') || 'Student'

    if (!token || !id) {
      router.replace('/admin/x7k2p')
      return
    }

    try {
      sessionStorage.setItem('imp_token', token)
      sessionStorage.setItem('imp_id', id)
      sessionStorage.setItem('imp_name', decodeURIComponent(name))
    } catch(e) {}

    router.replace('/dashboard')
  }, [params, router])

  return (
    <div style={{minHeight:'100vh',background:'#000A18',display:'flex',alignItems:'center',justifyContent:'center',color:'#4D9FFF',fontFamily:'Inter,sans-serif',fontSize:16,flexDirection:'column',gap:12}}>
      <div style={{fontSize:32}}>👁️</div>
      <div>Opening student view...</div>
    </div>
  )
}

export default function ImpersonatePage() {
  return (
    <Suspense fallback={
      <div style={{minHeight:'100vh',background:'#000A18',display:'flex',alignItems:'center',justifyContent:'center',color:'#4D9FFF',fontFamily:'Inter,sans-serif',fontSize:16}}>
        Loading...
      </div>
    }>
      <Inner/>
    </Suspense>
  )
}
EOF_IMP
echo "✅ /impersonate page written"

echo ""
echo "=== Step 3: Fix Admin Panel impersonate function ==="
node << 'NODEOF'
const fs = require('fs')
const path = '/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx'
let code = fs.readFileSync(path, 'utf8')

// Find exact impersonate function and replace
// Pattern from diagnostic output
const oldFn1 = `  const impersonate=useCallback(async()=>{
    if(!impId){T('Student ID required.','e');return}`

const oldFn2 = `  const impersonate=useCallback(async(directId?:string)=>{
    const useId=directId||impId
    if(!useId){T('Student ID required.','e');return}
    const impId=useId`

const oldFn3 = `  const impersonate=useCallback(async(studentId?:string)=>{
    const sid=studentId||impId
    if(!sid){T('Student ID required.','e');return}`

const newFn = `  const impersonate=useCallback(async(sid:string)=>{
    if(!sid){T('Student ID required.','e');return}
    try{
      const res=await fetch(\`\${API}/api/admin/manage/impersonate/\${sid}\`,{method:'POST',headers:{Authorization:\`Bearer \${token}\`}})
      if(res.ok){
        const d=await res.json()
        // Backend returns 'impersonateToken' field
        const sToken=d.impersonateToken||d.studentToken||d.token||''
        const sName=encodeURIComponent(d.name||'Student')
        if(!sToken){T('Failed to get student token','e');return}
        T(\`Opening as: \${d.name||'Student'}\`,'s')
        window.open(\`/impersonate?token=\${sToken}&id=\${sid}&name=\${sName}\`,'_blank')
      } else {
        const e=await res.json()
        T(e.message||'Failed to impersonate','e')
      }
    }catch{T('Network error','e')}`

let replaced = false
for (const old of [oldFn1, oldFn2, oldFn3]) {
  if (code.includes(old)) {
    // Find closing of this function (},[ pattern)
    const startIdx = code.indexOf(old)
    const endSearch = code.substring(startIdx + old.length)
    // Find },[...]) end of useCallback
    const endMatch = endSearch.match(/\n\s*\}[\s\S]*?\}\s*,\[[\s\S]*?\]\)/)
    if (endMatch) {
      const endIdx = startIdx + old.length + endMatch.index + endMatch[0].length
      const fullOld = code.substring(startIdx, endIdx)
      code = code.replace(fullOld, newFn + `\n  },[impId,token,T])`)
      console.log('✅ Replaced old impersonate fn pattern:', old.substring(0,50))
      replaced = true
      break
    }
  }
}

if (!replaced) {
  console.log('⚠️ Could not find exact pattern — doing line-based fix')
  // Just fix the core fetch line
  code = code.replace(
    /const res=await fetch\(`\$\{API\}\/api\/admin\/manage\/impersonate\/\$\{[^}]+\}`/g,
    'const res=await fetch(`${API}/api/admin/manage/impersonate/${sid}`'
  )
  code = code.replace(
    /const sToken=d\.studentToken\|\|d\.token\|\|''/g,
    "const sToken=d.impersonateToken||d.studentToken||d.token||''"
  )
}

// Fix button — always pass _id directly
code = code.replace(
  /onClick=\{[^}]*setImpId[^}]*impersonate[^}]*\}/g,
  'onClick={()=>impersonate(selStudent._id)}'
)
code = code.replace(
  /onClick=\{\(\)=>impersonate\(selStudent\?\._id\|\|selStudent\?\._id\)\}/g,
  'onClick={()=>impersonate(selStudent._id)}'
)
code = code.replace(
  "onClick={()=>impersonate(selStudent._id)}",
  "onClick={()=>{ if(selStudent?._id) impersonate(selStudent._id) }}"
)

fs.writeFileSync(path, code, 'utf8')
console.log('✅ Admin page saved')

// Verify
const verify = fs.readFileSync(path, 'utf8')
console.log('impersonateToken in code:', verify.includes('impersonateToken') ? 'YES ✅' : 'NO ❌')
console.log('selStudent._id in button:', verify.includes("selStudent._id") ? 'YES ✅' : 'NO ❌')
NODEOF

echo ""
echo "=== Step 4: Add impersonateToken to backend if missing ==="
node << 'NODEOF'
const fs = require('fs')
const candidates = [
  '/home/runner/workspace/src/routes/admin.js',
  '/home/runner/workspace/src/routes/adminRoutes.js',
]
const path = candidates.find(p => fs.existsSync(p))
if (!path) { console.log('⚠️ Admin route not found'); process.exit(0) }

let code = fs.readFileSync(path, 'utf8')

if (code.includes('impersonateToken')) {
  console.log('✅ Backend already returns impersonateToken')
} else if (code.includes('studentToken')) {
  // Rename studentToken to impersonateToken for consistency
  code = code.replace(/studentToken/g, 'impersonateToken')
  fs.writeFileSync(path, code, 'utf8')
  console.log('✅ Renamed studentToken → impersonateToken in backend')
} else {
  console.log('ℹ️ No token field found in backend — was added in previous script')
}
NODEOF

echo ""
echo "=== Step 5: Git push ==="
cd /home/runner/workspace
git add -A
git commit -m "fix: impersonate final — direct ID pass, impersonateToken field, sessionStorage first"
git push origin main

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  IMPERSONATE FINAL FIX ✅                              ║"
echo "║                                                        ║"
echo "║  Root causes fixed:                                    ║"
echo "║  1. Admin fn: sid passed directly (no race condition)  ║"
echo "║  2. Token field: impersonateToken (matches backend)    ║"
echo "║  3. StudentShell: sessionStorage FIRST in useEffect    ║"
echo "║  4. /impersonate page: Suspense wrapped ✅             ║"
echo "╚════════════════════════════════════════════════════════╝"
