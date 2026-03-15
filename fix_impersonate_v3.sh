#!/bin/bash
node << 'NODEOF'
const fs = require('fs')

// ── Fix 1: Admin page — impersonate opens new tab with token ──
const adminCandidates = [
  '/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx',
  '/home/runner/workspace/frontend/src/app/admin/x7k2p/page.tsx',
]
const adminPath = adminCandidates.find(p => fs.existsSync(p))
if (!adminPath) { console.log('❌ Admin page not found'); process.exit(1) }

let adminCode = fs.readFileSync(adminPath, 'utf8')

// Fix impersonate — store student token in sessionStorage and open dashboard
const oldImpersonate = `const impersonate=useCallback(async(directId?:string)=>{
    const useId=directId||impId
    if(!useId){T('Student ID required.','e');return}
    const impId=useId`

const newImpersonate = `const impersonate=useCallback(async(directId?:string)=>{
    const useId=directId||impId
    if(!useId){T('Student ID required.','e');return}`

adminCode = adminCode.replace(oldImpersonate, newImpersonate)

// Fix the fetch and window.open part
adminCode = adminCode.replace(
  `const res=await fetch(\`\${API}/api/admin/manage/impersonate/\${useId}\`,{method:'POST',headers:{Authorization:\`Bearer \${token}\`}})
      if(res.ok){const d=await res.json();T(\`Viewing as: \${d.name||useId}\`);window.open(\`/dashboard?impersonate=\${useId}\`,'_blank')}`,
  `const res=await fetch(\`\${API}/api/admin/manage/impersonate/\${useId}\`,{method:'POST',headers:{Authorization:\`Bearer \${token}\`}})
      if(res.ok){
        const d=await res.json()
        // Store student token in sessionStorage for new tab
        const studentToken=d.studentToken||d.token
        const msg=\`Viewing as: \${d.name||useId}\`
        T(msg,'s')
        // Open new tab with impersonate token
        const url=\`/dashboard?imp_token=\${studentToken||''}&imp_id=\${useId}&imp_name=\${encodeURIComponent(d.name||'Student')}\`
        window.open(url,'_blank')
      }`
)

fs.writeFileSync(adminPath, adminCode, 'utf8')
console.log('✅ Admin impersonate fixed')

// ── Fix 2: StudentShell — allow impersonate mode ──
const shellPath = '/home/runner/workspace/frontend/src/components/StudentShell.tsx'
if (!fs.existsSync(shellPath)) { console.log('❌ StudentShell not found'); process.exit(1) }

let shellCode = fs.readFileSync(shellPath, 'utf8')

// Fix useEffect — check for imp_token in URL, if present skip role redirect
const oldEffect = `    const tk=_gt()
    if(!tk){ router.replace('/login'); return }

    const r=_gr()

    // ── ROLE GUARD: Admin/Superadmin must go to Admin Panel ──
    if(r==='admin'||r==='superadmin'){
      router.replace('/admin/x7k2p')
      return
    }`

const newEffect = `    // Check if this is an impersonate session (admin viewing as student)
    const urlParams = typeof window !== 'undefined' ? new URLSearchParams(window.location.search) : null
    const impToken = urlParams?.get('imp_token')
    const impId    = urlParams?.get('imp_id')
    const impName  = urlParams?.get('imp_name')

    if(impToken && impId) {
      // Impersonate mode — use student token, show student dashboard
      setToken(impToken)
      setRole('student')
      setUser({ _id: impId, name: decodeURIComponent(impName||'Student'), role: 'student' })
      try { localStorage.setItem('imp_mode','1') } catch{}
      setMounted(true)
      return
    }

    const tk=_gt()
    if(!tk){ router.replace('/login'); return }

    const r=_gr()

    // ── ROLE GUARD: Admin/Superadmin must go to Admin Panel ──
    if(r==='admin'||r==='superadmin'){
      router.replace('/admin/x7k2p')
      return
    }`

shellCode = shellCode.replace(oldEffect, newEffect)

// Add impersonate banner in topbar
shellCode = shellCode.replace(
  `{toastSt&&(`,
  `{typeof window!=='undefined'&&new URLSearchParams(window.location.search).get('imp_id')&&(
          <div style={{position:'fixed',top:0,left:0,right:0,zIndex:9998,padding:'8px 16px',background:'linear-gradient(90deg,#FF6B00,#FF8C00)',color:'#fff',textAlign:'center',fontSize:12,fontWeight:700,display:'flex',justifyContent:'space-between',alignItems:'center'}}>
            <span>👁️ Impersonate Mode — Viewing as Student</span>
            <button onClick={()=>window.close()} style={{background:'rgba(0,0,0,.3)',border:'none',color:'#fff',borderRadius:6,padding:'3px 10px',cursor:'pointer',fontFamily:'Inter,sans-serif',fontSize:11,fontWeight:700}}>✕ Close</button>
          </div>
        )}
        {toastSt&&(`
)

fs.writeFileSync(shellPath, shellCode, 'utf8')
console.log('✅ StudentShell impersonate mode added')
NODEOF

cd /home/runner/workspace
git add -A
git commit -m "fix: impersonate (M4) — use imp_token URL param, skip role redirect, show banner"
git push origin main
echo "✅ Done — View as Student will open in new tab without redirect"

# ── Fix 3: Backend — add/fix impersonate endpoint ──
node << 'NODEOF'
const fs = require('fs')
const candidates = [
  '/home/runner/workspace/src/routes/admin.js',
  '/home/runner/workspace/src/routes/adminRoutes.js',
]
const path = candidates.find(p => fs.existsSync(p))
if (!path) { console.log('⚠️ Admin route not found'); process.exit(0) }

let code = fs.readFileSync(path, 'utf8')

if (!code.includes('/impersonate/')) {
  const route = `
// Impersonate student (M4) — returns a student JWT
router.post('/manage/impersonate/:studentId', async (req, res) => {
  try {
    const mongoose = require('mongoose')
    const jwt = require('jsonwebtoken')
    const User = require('../models/User')
    const JWT_SECRET = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024'

    const student = await User.collection.findOne({
      _id: new mongoose.Types.ObjectId(req.params.studentId)
    })
    if (!student) return res.status(404).json({ message: 'Student not found' })

    // Generate a short-lived student token for impersonation
    const studentToken = jwt.sign(
      { id: student._id.toString(), role: 'student', impersonated: true },
      JWT_SECRET,
      { expiresIn: '2h' }
    )
    res.json({
      studentToken,
      name: student.name,
      email: student.email,
      message: 'Impersonation token generated'
    })
  } catch(err) {
    console.error('Impersonate error:', err)
    res.status(500).json({ message: 'Server error' })
  }
})
`
  code = code.replace('module.exports', route + '\nmodule.exports')
  fs.writeFileSync(path, code, 'utf8')
  console.log('✅ Impersonate backend endpoint added')
} else {
  console.log('✅ Impersonate endpoint already exists')
}
NODEOF

cd /home/runner/workspace
git add -A
git commit -m "feat: impersonate backend endpoint — returns studentToken for view as student"
git push origin main
echo "✅ All fixes pushed"
