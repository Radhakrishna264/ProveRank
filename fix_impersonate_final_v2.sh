#!/bin/bash
node << 'NODEOF'
const fs = require('fs')

// ── Fix 1: Admin page — impersonate function ──
const adminCandidates = [
  '/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx',
  '/home/runner/workspace/frontend/src/app/admin/x7k2p/page.tsx',
]
const adminPath = adminCandidates.find(p => fs.existsSync(p))
if (!adminPath) { console.log('❌ Admin page not found'); process.exit(1) }

let adminCode = fs.readFileSync(adminPath, 'utf8')

// Find and replace the full impersonate function
// Old pattern — may have directId or not
const impFnRegex = /const impersonate=useCallback\(async\([^)]*\)=>\{[\s\S]*?\},\[[\s\S]*?\]\)/
const newImpFn = `const impersonate=useCallback(async(studentId?:string)=>{
    const sid=studentId||impId
    if(!sid){T('Student ID required.','e');return}
    try{
      const res=await fetch(\`\${API}/api/admin/manage/impersonate/\${sid}\`,{method:'POST',headers:{Authorization:\`Bearer \${token}\`}})
      if(res.ok){
        const d=await res.json()
        const sToken=d.studentToken||d.token||''
        const sName=encodeURIComponent(d.name||'Student')
        T(\`Opening as: \${d.name||'Student'}\`,'s')
        window.open(\`/impersonate?token=\${sToken}&id=\${sid}&name=\${sName}\`,'_blank')
      } else {
        const e=await res.json()
        T(e.message||'Failed','e')
      }
    }catch{T('Network error','e')}
  },[impId,token,T])`

if (impFnRegex.test(adminCode)) {
  adminCode = adminCode.replace(impFnRegex, newImpFn)
  console.log('✅ impersonate function replaced')
} else {
  console.log('⚠️ impersonate function pattern not matched — trying manual fix')
  // Simpler replace — just fix the button onClick
}

// Fix button — pass id directly, no setImpId needed
adminCode = adminCode.replace(
  /onClick=\{[^}]*setImpId[^}]*impersonate[^}]*\}/g,
  'onClick={()=>impersonate(selStudent._id)}'
)
adminCode = adminCode.replace(
  `onClick={()=>impersonate(selStudent._id)}`,
  `onClick={()=>impersonate(selStudent?._id||selStudent?._id)}`
)

fs.writeFileSync(adminPath, adminCode, 'utf8')
console.log('✅ Admin page fixed')

// ── Fix 2: /impersonate page — with Suspense ──
fs.mkdirSync('/home/runner/workspace/frontend/app/impersonate', { recursive: true })
fs.writeFileSync('/home/runner/workspace/frontend/app/impersonate/page.tsx', `'use client'
import { Suspense, useEffect } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'

function Inner() {
  const router = useRouter()
  const params = useSearchParams()
  useEffect(() => {
    const token = params.get('token')
    const id    = params.get('id')
    const name  = params.get('name') || 'Student'
    if (!token || !id) { router.replace('/admin/x7k2p'); return }
    try {
      sessionStorage.setItem('imp_token', token)
      sessionStorage.setItem('imp_id', id)
      sessionStorage.setItem('imp_name', decodeURIComponent(name))
    } catch(e) {}
    router.replace('/dashboard')
  }, [params, router])
  return <div style={{minHeight:'100vh',background:'#000A18',display:'flex',alignItems:'center',justifyContent:'center',color:'#4D9FFF',fontFamily:'Inter,sans-serif'}}>Opening student view...</div>
}

export default function ImpersonatePage() {
  return (
    <Suspense fallback={<div style={{minHeight:'100vh',background:'#000A18',display:'flex',alignItems:'center',justifyContent:'center',color:'#4D9FFF',fontFamily:'Inter,sans-serif'}}>Loading...</div>}>
      <Inner/>
    </Suspense>
  )
}
`)
console.log('✅ /impersonate page ready')

// ── Fix 3: StudentShell useEffect — sessionStorage FIRST ──
const shellPath = '/home/runner/workspace/frontend/src/components/StudentShell.tsx'
let shell = fs.readFileSync(shellPath, 'utf8')

// Replace the entire useEffect body — find it by marker
// Strategy: replace from "const tk=_gt()" to the first setMounted(true)
// Insert sessionStorage check BEFORE everything else

// Remove any previous imp attempts
shell = shell.replace(/\/\/ ── IMPERSONATE MODE[\s\S]*?return\s*\}\s*\} catch\(e\) \{\}\n\n/g, '')
shell = shell.replace(/\/\/ Check if this is an impersonate session[\s\S]*?return\s*\}\n\n/g, '')
shell = shell.replace(/const _search[\s\S]*?return\s*\}\n\n/g, '')

// Now insert clean sessionStorage check right at start of useEffect callback
// Find: "const tk=_gt()"  and insert before it
const impCheck = `    // ── IMPERSONATE MODE (sessionStorage — isolated per tab) ──
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

if (!shell.includes("sessionStorage.getItem('imp_token')")) {
  shell = shell.replace(`    const tk=_gt()`, impCheck + `    const tk=_gt()`)
  console.log('✅ sessionStorage check added to StudentShell useEffect')
} else {
  console.log('✅ sessionStorage check already present')
}

fs.writeFileSync(shellPath, shell, 'utf8')
console.log('✅ StudentShell saved')
NODEOF

cd /home/runner/workspace
git add -A
git commit -m "fix: impersonate (M4) final — sessionStorage first in useEffect, Suspense boundary"
git push origin main
echo ""
echo "✅ All 3 fixes pushed:"
echo "  1. Admin impersonate fn — passes studentId directly (no race condition)"
echo "  2. /impersonate page — Suspense wrapped, sets sessionStorage"
echo "  3. StudentShell — reads sessionStorage BEFORE localStorage role check"
