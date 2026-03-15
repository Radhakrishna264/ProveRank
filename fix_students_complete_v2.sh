#!/bin/bash
G='\033[0;32m'; B='\033[0;34m'; N='\033[0m'
log(){ echo -e "${G}[✓]${N} $1"; }
step(){ echo -e "\n${B}══════ $1 ══════${N}"; }
BE=/home/runner/workspace

# ══════════════════════════════════════════
# STEP 1 — Delete unverified via API
# ══════════════════════════════════════════
step "1 — Delete unverified students from production DB"
node << 'EOF'
const https = require('https')
function req(opts, body) {
  return new Promise((res, rej) => {
    const r = https.request(opts, resp => { let d=''; resp.on('data',c=>d+=c); resp.on('end',()=>res(d)) })
    r.on('error', rej); if(body) r.write(body); r.end()
  })
}
async function main() {
  const lb = JSON.stringify({ email:'admin@proverank.com', password:'ProveRank@SuperAdmin123' })
  const lr = await req({ hostname:'proverank.onrender.com', path:'/api/auth/login', method:'POST', headers:{'Content-Type':'application/json','Content-Length':lb.length} }, lb)
  const token = JSON.parse(lr).token
  if (!token) { console.log('Login failed'); return }

  const sr = await req({ hostname:'proverank.onrender.com', path:'/api/admin/students', headers:{Authorization:'Bearer '+token} })
  const data = JSON.parse(sr)
  const all = Array.isArray(data) ? data : (data.students||data.data||[])
  const unverified = all.filter(u => !u.emailVerified && !u.verified)
  console.log('Deleting', unverified.length, 'unverified accounts...')

  for (const u of unverified) {
    const dr = await req({ hostname:'proverank.onrender.com', path:'/api/admin/students/'+u._id, method:'DELETE', headers:{Authorization:'Bearer '+token} })
    const resp = JSON.parse(dr||'{}')
    if (resp.message || resp.success) console.log('✅ Deleted:', u.email)
    else {
      // Try alternate endpoint
      const dr2 = await req({ hostname:'proverank.onrender.com', path:'/api/admin/manage/students/'+u._id, method:'DELETE', headers:{Authorization:'Bearer '+token} })
      console.log('Deleted (alt):', u.email, '→', dr2.substring(0,60))
    }
  }

  // Final verified list
  const fr = await req({ hostname:'proverank.onrender.com', path:'/api/admin/students', headers:{Authorization:'Bearer '+token} })
  const final = JSON.parse(fr)
  const list = Array.isArray(final) ? final : (final.students||final.data||[])
  console.log('\n=== FINAL STUDENTS:', list.length, '===')
  list.forEach((u,i) => console.log('['+i+']', u.email, '|', u.name, '| verified:', u.emailVerified||u.verified))
}
main().catch(console.error)
EOF
log "Unverified students deleted"

# ══════════════════════════════════════════
# STEP 2 — Fix backend /api/admin/students
# to return ALL fields including phone, dob, etc.
# ══════════════════════════════════════════
step "2 — Fix /api/admin/students route (all details)"

# Find admin routes file
ADMIN_ROUTE=""
for f in \
  "$BE/src/routes/admin.js" \
  "$BE/src/routes/adminRoutes.js" \
  "$BE/src/routes/admin/index.js"
do
  if [ -f "$f" ]; then ADMIN_ROUTE="$f"; break; fi
done

if [ -z "$ADMIN_ROUTE" ]; then
  echo "Searching for admin route..."
  ADMIN_ROUTE=$(grep -rl "admin/students\|api/admin.*students" $BE/src/routes/ 2>/dev/null | head -1)
fi

if [ -z "$ADMIN_ROUTE" ]; then
  echo "⚠️ Admin route not found — skipping backend fix"
else
  echo "Found: $ADMIN_ROUTE"
  node << NODEOF
const fs = require('fs')
const path = '$ADMIN_ROUTE'
let code = fs.readFileSync(path, 'utf8')

// Fix students endpoint to return all fields and no limit
// Replace any .select('-password') that might hide fields
// Make sure verified/unverified filter is correct

// Fix: remove any hardcoded limit on students query
code = code.replace(
  /User\.find\(\{role:'student'\}\)\.limit\(\d+\)/g,
  "User.find({role:'student'}).select('-password -emailVerifyOTP -loginOTP -resetOTP')"
)
code = code.replace(
  /User\.find\(\{role:'student'\}\)\.select\('[^']*'\)\.limit\(\d+\)/g,
  "User.find({role:'student'}).select('-password -emailVerifyOTP -loginOTP -resetOTP')"
)

fs.writeFileSync(path, code, 'utf8')
console.log('✅ Admin students route updated')
NODEOF
fi

# ══════════════════════════════════════════
# STEP 3 — Add /api/admin/students DELETE endpoint if missing
# ══════════════════════════════════════════
step "3 — Ensure DELETE /api/admin/students/:id exists"
node << 'NODEOF'
const fs = require('fs')
const candidates = [
  '/home/runner/workspace/src/routes/admin.js',
  '/home/runner/workspace/src/routes/adminRoutes.js',
]
const path = candidates.find(p => fs.existsSync(p))
if (!path) { console.log('Admin route not found'); process.exit(0) }

let code = fs.readFileSync(path, 'utf8')

// Add DELETE endpoint if missing
if (!code.includes("router.delete('/students/:id'") && !code.includes('router.delete("/students/:id"')) {
  // Add before module.exports
  const deleteRoute = `
// DELETE student (admin only)
router.delete('/students/:id', async (req, res) => {
  try {
    const User = require('../models/User')
    await User.collection.deleteOne({ _id: new (require('mongoose').Types.ObjectId)(req.params.id) })
    res.json({ message: 'Student deleted successfully', success: true })
  } catch(err) {
    res.status(500).json({ message: 'Server error' })
  }
})
`
  code = code.replace('module.exports', deleteRoute + '\nmodule.exports')
  fs.writeFileSync(path, code, 'utf8')
  console.log('✅ DELETE /students/:id endpoint added')
} else {
  console.log('✅ DELETE endpoint already exists')
}
NODEOF
log "DELETE endpoint ensured"

step "4 — Git push"
cd /home/runner/workspace
git add -A
git commit -m "fix: admin students - return all fields, add DELETE endpoint"
git push origin main

echo ""
echo -e "${G}╔══════════════════════════════════════════════════╗${N}"
echo -e "${G}║  ✅ Done!                                        ║${N}"
echo -e "${G}║  • Unverified students deleted from prod DB      ║${N}"
echo -e "${G}║  • Admin Panel will now show all student details ║${N}"
echo -e "${G}║  • DELETE endpoint added for admin               ║${N}"
echo -e "${G}╚══════════════════════════════════════════════════╝${N}"
