#!/bin/bash
node << 'NODEOF'
const fs = require('fs')

const shellPath = '/home/runner/workspace/frontend/src/components/StudentShell.tsx'
if (!fs.existsSync(shellPath)) { console.log('❌ StudentShell not found'); process.exit(1) }

let code = fs.readFileSync(shellPath, 'utf8')

// Find the full useEffect and replace it completely
// The fix: read URL params FIRST before any localStorage/role check
const oldEffect = code.match(/useEffect\(\(\)=>\{[\s\S]*?router\]?\)(\s*\/\/ eslint.*)?(\n)/)?.[0]

// Replace the role guard section - find the specific part
code = code.replace(
  `    // ── ROLE GUARD: Admin/Superadmin must go to Admin Panel ──
    if(r==='admin'||r==='superadmin'){
      router.replace('/admin/x7k2p')
      return
    }`,
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
    }`
)

fs.writeFileSync(shellPath, code, 'utf8')
console.log('✅ StudentShell impersonate check added before role guard')

// Verify
const verify = fs.readFileSync(shellPath, 'utf8')
console.log('imp_token check present:', verify.includes('imp_token') ? 'YES ✅' : 'NO ❌')
NODEOF

cd /home/runner/workspace
git add -A
git commit -m "fix: impersonate — check imp_token URL param BEFORE role guard redirect"
git push origin main
echo "✅ Pushed"
