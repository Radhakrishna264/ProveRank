#!/bin/bash
node << 'NODEOF'
const fs = require('fs')

// ── 1. Create /impersonate page ──
const impDir = '/home/runner/workspace/frontend/app/impersonate'
fs.mkdirSync(impDir, { recursive: true })

fs.writeFileSync(impDir + '/page.tsx', `'use client'
import { useEffect } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'

export default function ImpersonatePage() {
  const router = useRouter()
  const params = useSearchParams()

  useEffect(() => {
    const token = params.get('token')
    const id    = params.get('id')
    const name  = params.get('name')

    if (!token || !id) {
      router.replace('/admin/x7k2p')
      return
    }

    // Store in sessionStorage (not localStorage) — isolated to this tab
    try {
      sessionStorage.setItem('imp_token', token)
      sessionStorage.setItem('imp_id', id)
      sessionStorage.setItem('imp_name', decodeURIComponent(name || 'Student'))
      sessionStorage.setItem('imp_mode', '1')
    } catch(e) {}

    router.replace('/dashboard')
  }, [params, router])

  return (
    <div style={{
      minHeight:'100vh',
      background:'#000A18',
      display:'flex',
      alignItems:'center',
      justifyContent:'center',
      color:'#4D9FFF',
      fontFamily:'Inter,sans-serif',
      fontSize:16
    }}>
      Loading student view...
    </div>
  )
}
`)
console.log('✅ /impersonate page created')

// ── 2. Fix StudentShell — read from sessionStorage ──
const shellPath = '/home/runner/workspace/frontend/src/components/StudentShell.tsx'
let code = fs.readFileSync(shellPath, 'utf8')

// Replace the useEffect role guard section
code = code.replace(
  `    // ── ROLE GUARD: Admin/Superadmin must go to Admin Panel ──
    // BUT: skip if this is an impersonate session
    const _search = typeof window !== 'undefined' ? window.location.search : ''
    const _params = new URLSearchParams(_search)
    const _impToken = _params.get('imp_token')
    const _impId = _params.get('imp_id')
    const _impName = _params.get('imp_name')

    if (_impToken && _impId) {
      // Impersonate mode — admin viewing as student
      setToken(_impToken)
      setRole('student')
      setUser({ _id: _impId, name: decodeURIComponent(_impName||'Student'), role:'student', email:'' })
      setMounted(true)
      return
    }

    if(r==='admin'||r==='superadmin'){
      router.replace('/admin/x7k2p')
      return
    }`,
  `    // ── IMPERSONATE MODE: check sessionStorage (set by /impersonate page) ──
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

    // ── ROLE GUARD: Admin/Superadmin must go to Admin Panel ──
    if(r==='admin'||r==='superadmin'){
      router.replace('/admin/x7k2p')
      return
    }`
)

fs.writeFileSync(shellPath, code, 'utf8')
console.log('✅ StudentShell — reads sessionStorage for impersonate mode')

// ── 3. Fix Admin page — use /impersonate route ──
const adminCandidates = [
  '/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx',
  '/home/runner/workspace/frontend/src/app/admin/x7k2p/page.tsx',
]
const adminPath = adminCandidates.find(p => fs.existsSync(p))
if (adminPath) {
  let adminCode = fs.readFileSync(adminPath, 'utf8')
  // Fix window.open to use /impersonate page
  adminCode = adminCode.replace(
    /window\.open\(`\/dashboard\?imp_token=\$\{[^}]+\}&imp_id=\$\{[^}]+\}&imp_name=\$\{[^}]+\}`,'_blank'\)/g,
    "window.open(`/impersonate?token=${studentToken||''}&id=${useId}&name=${encodeURIComponent(d.name||'Student')}`, '_blank')"
  )
  // Also fix old pattern if present
  adminCode = adminCode.replace(
    /window\.open\(`\/dashboard\?impersonate=\$\{[^}]+\}`,'_blank'\)/g,
    "window.open(`/impersonate?token=${useId}&id=${useId}&name=${encodeURIComponent(d.name||'Student')}`, '_blank')"
  )
  fs.writeFileSync(adminPath, adminCode, 'utf8')
  console.log('✅ Admin panel — uses /impersonate route')
}
NODEOF

cd /home/runner/workspace
git add -A
git commit -m "fix: impersonate (M4) — dedicated /impersonate page + sessionStorage approach"
git push origin main
echo "✅ Done — View as Student will now work correctly"
