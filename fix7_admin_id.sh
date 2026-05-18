#!/bin/bash
# Fix#7 — Admin ID Auto-Generation (Format: PRAxxXYZ)
# Run: bash fix7_admin_id.sh

echo "🚀 Starting Fix#7..."

# ─── STEP 1: Add adminId field to User.js model ──────────────────────────────
node << 'EOF'
const fs = require('fs')
const UP = '/home/runner/workspace/src/models/User.js'
let c = fs.readFileSync(UP, 'utf8')

if(c.includes('adminId:')){
  console.log('✅ adminId already in User.js model')
} else {
  // Add adminId after studentId if exists, else after email field
  const targets = [
    `studentId: { type: String, unique: true, sparse: true, trim: true }`,
    `email: { type: String, required: true, unique: true`,
  ]
  let added = false
  for(const t of targets){
    if(c.includes(t)){
      c = c.replace(t, t + `,\n  adminId: { type: String, unique: true, sparse: true, trim: true }`)
      added = true
      console.log('✅ adminId field added to User.js after:', t.substring(0,30))
      break
    }
  }
  if(!added){
    // Fallback: add before closing of schema object
    c = c.replace(`  role: {`, `  adminId: { type: String, unique: true, sparse: true, trim: true },\n  role: {`)
    console.log('✅ adminId field added to User.js (fallback before role)')
  }
  fs.writeFileSync(UP, c)
}
EOF

# ─── STEP 2: Add adminId generation in create-admin backend route ────────────
node << 'EOF'
const fs = require('fs')
const AP = '/home/runner/workspace/src/routes/admin.js'
let c = fs.readFileSync(AP, 'utf8')

if(c.includes('generateAdminId')){
  console.log('✅ generateAdminId already in admin.js')
} else {
  // Add the generator function at top of file (after first require)
  const firstRequire = c.indexOf("require(")
  const lineEnd = c.indexOf('\n', firstRequire)
  const genFn = `
function generateAdminId(year) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  let xyz = ''
  for(let i = 0; i < 3; i++) xyz += chars[Math.floor(Math.random() * chars.length)]
  return 'PRA' + String(year).slice(-2) + xyz
}
`
  c = c.substring(0, lineEnd + 1) + genFn + c.substring(lineEnd + 1)
  console.log('✅ generateAdminId function added to admin.js')
  fs.writeFileSync(AP, c)
}

// Re-read after potential write
c = fs.readFileSync(AP, 'utf8')

// Now find the create-admin route and add adminId generation before save
// Pattern: find 'create-admin' route and the user.save() call inside it
const createAdminIdx = c.indexOf("'create-admin'")
if(createAdminIdx === -1){
  const alt = c.indexOf('"create-admin"') !== -1 ? c.indexOf('"create-admin"') : c.indexOf('/create-admin')
  console.log('create-admin route found at idx:', alt)
}

// Find user.save() near the create-admin route
const routeStart = c.indexOf("'create-admin'")
if(routeStart !== -1){
  const routeSection = c.substring(routeStart, routeStart + 2000)
  const saveIdx = routeSection.indexOf('.save()')
  if(saveIdx !== -1){
    const globalSaveIdx = routeStart + saveIdx
    // Check if adminId already being set
    const beforeSave = c.substring(globalSaveIdx - 300, globalSaveIdx)
    if(beforeSave.includes('adminId')){
      console.log('✅ adminId already being set before save in create-admin route')
    } else {
      // Find the variable name of the new user (e.g. newUser, user, admin)
      // Look for: const xxx = new User(
      const newUserMatch = routeSection.match(/const\s+(\w+)\s*=\s*new User\(/)
      const varName = newUserMatch ? newUserMatch[1] : 'newUser'
      console.log('New user variable name:', varName)

      const adminIdCode = `
  // Generate unique Admin ID
  let _adminId, _adminUnique = false, _adminTries = 0
  while(!_adminUnique && _adminTries < 30){
    _adminId = generateAdminId(new Date().getFullYear())
    const _existing = await User.findOne({ adminId: _adminId })
    if(!_existing) _adminUnique = true
    _adminTries++
  }
  ${varName}.adminId = _adminId
`
      // Insert before .save()
      c = c.substring(0, globalSaveIdx) + adminIdCode + c.substring(globalSaveIdx)
      fs.writeFileSync(AP, c)
      console.log('✅ adminId generation added before', varName + '.save() in create-admin route')
    }
  } else {
    console.log('⚠️ .save() not found near create-admin route - showing context:')
    console.log(routeSection.substring(0, 500))
  }
} else {
  // Try alternate - find by POST and create
  const idx2 = c.indexOf('/create-admin')
  console.log('⚠️ create-admin route not found with quotes. idx:', idx2)
  if(idx2 !== -1){
    console.log('Context:', c.substring(idx2, idx2+300))
  }
}
EOF

# ─── STEP 3: Migration — generate adminId for existing admins ─────────────────
echo "📦 Running migration for existing admins..."
cat > /home/runner/workspace/migrate_admin_ids.js << 'MIGEOF'
require('dotenv').config()
const mongoose = require('mongoose')

const MONGO_URI = process.env.MONGO_URI
if(!MONGO_URI){ console.error('MONGO_URI not found'); process.exit(1) }

function generateAdminId(year){
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  let xyz = ''
  for(let i=0;i<3;i++) xyz += chars[Math.floor(Math.random()*chars.length)]
  return 'PRA' + String(year).slice(-2) + xyz
}

async function migrate(){
  await mongoose.connect(MONGO_URI)
  console.log('✅ MongoDB connected — DB:', mongoose.connection.db.databaseName)
  const col = mongoose.connection.db.collection('students')

  const admins = await col.find({
    role: { $in: ['admin','superadmin'] },
    $or: [{ adminId: { $exists: false } }, { adminId: null }, { adminId: '' }]
  }).toArray()

  console.log(`Found ${admins.length} admins without adminId`)

  let updated = 0
  for(const a of admins){
    const year = a.createdAt ? new Date(a.createdAt).getFullYear() : 2025
    let adminId, isUnique = false, tries = 0
    while(!isUnique && tries < 30){
      adminId = generateAdminId(year)
      const exists = await col.findOne({ adminId })
      if(!exists) isUnique = true
      tries++
    }
    await col.updateOne({ _id: a._id }, { $set: { adminId } })
    console.log(`✅ ${a.email} (${a.role}) → ${adminId}`)
    updated++
  }
  console.log(`\nMigration done! ${updated} admins updated.`)
  await mongoose.disconnect()
}
migrate().catch(e => { console.error('Error:', e.message); process.exit(1) })
MIGEOF

cd /home/runner/workspace && node migrate_admin_ids.js

# ─── STEP 4: Frontend — Add adminId to profileAdmin modal + admin cards ───────
node << 'EOF'
const fs = require('fs')
const FP = '/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx'
let c = fs.readFileSync(FP, 'utf8')

// Fix 1: Add adminId in profileAdmin modal — after email line
// Target the email display in profileAdmin detail
const old1 = `{profileAdmin.email||'-'}</div>`
const new1 = `{profileAdmin.email||'-'}</div>
                  {(profileAdmin as any).adminId&&<div style={{display:'inline-flex',alignItems:'center',gap:6,marginTop:5,marginBottom:2,padding:'3px 10px',background:'rgba(0,180,255,0.08)',borderRadius:6,border:'1px solid rgba(0,180,255,0.2)',width:'fit-content'}}>
                    <span style={{fontSize:9,color:'#6B8FAF',letterSpacing:1.5,textTransform:'uppercase',fontWeight:700}}>Admin ID</span>
                    <span style={{fontSize:12,fontWeight:800,color:'#00B4FF',fontFamily:'monospace',letterSpacing:2}}>{(profileAdmin as any).adminId}</span>
                    <CopyBtn text={(profileAdmin as any).adminId} size="sm"/>
                  </div>}`

if(c.includes(old1)){
  c = c.replace(old1, new1)
  console.log('✅ adminId added to profileAdmin modal (email section)')
} else {
  // Try profileAdmin.name version
  const old1b = `{profileAdmin.name||&#x2019;-&#x2019;}</div>`
  console.log('⚠️ profileAdmin email pattern not found, checking...')
  const emailIdx = c.indexOf('profileAdmin.email')
  if(emailIdx !== -1) console.log('profileAdmin.email context:', JSON.stringify(c.substring(emailIdx-20, emailIdx+80)))
}

// Fix 2: Add adminId to admin cards list (au variable cards)
// Find where au.email is shown in admin list cards (not profileAdmin modal)
// Pattern: au.email in a div near au.name
const auEmailPatterns = [
  `{au.email||&#x2019;-&#x2019;}`,
  `>{au.email}</`,
  `au.email||&#x2019;&#x2019;`,
]
let auFixed = false
for(const pat of auEmailPatterns){
  if(c.includes(pat)){
    console.log('Found au.email pattern:', pat)
    auFixed = true
    break
  }
}
if(!auFixed){
  // Search for au.email occurrences
  const matches = []
  let i = 0
  while(i < c.length){
    const fi = c.indexOf('au.email', i)
    if(fi === -1) break
    matches.push({idx:fi, ctx: c.substring(fi-30,fi+60)})
    i = fi + 1
  }
  console.log('au.email occurrences:', matches.length)
  matches.slice(0,3).forEach((m,i) => console.log(`  #${i+1}:`, JSON.stringify(m.ctx)))
}

fs.writeFileSync(FP, c)
console.log('✅ Frontend file saved')
EOF

# ─── STEP 5: Git push ─────────────────────────────────────────────────────────
echo ""
echo "📤 Git push..."
cd /home/runner/workspace
git add src/models/User.js src/routes/admin.js frontend/app/admin/x7k2p/page.tsx
git commit -m "Fix#7: Admin ID auto-generation (PRAxxXYZ) — backend model, create-admin route, migration, frontend display"
git push origin main
echo "✅ Fix#7 complete! Vercel deploying (~2 min)"
echo "🔄 Run migration script separately if needed: node migrate_admin_ids.js"
