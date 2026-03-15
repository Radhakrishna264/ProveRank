node << 'NODEOF'
const mongoose = require('./node_modules/mongoose')
require('dotenv').config()
const MONGO = process.env.MONGODB_URI || process.env.MONGO_URI

mongoose.connect(MONGO).then(async () => {
  const db = mongoose.connection.db
  const col = db.collection('users')

  // ── 1. Show ALL users with full details ──
  const all = await col.find({}).toArray()
  console.log('=== TOTAL IN DB:', all.length, '===\n')
  all.forEach((u,i) => {
    console.log(`[${i+1}] ${u.email} | role: ${u.role||'NO_ROLE'} | verified: ${u.emailVerified||u.verified||false} | created: ${u.createdAt?.toISOString?.()?.split('T')[0]||'N/A'}`)
  })

  // ── 2. Find fake admin accounts (t_177... pattern) ──
  const fakeAdmins = await col.find({
    role: 'admin',
    $or: [
      { email: /^t_177/ },
      { email: /^testadmin_177/ },
      { email: /^t\.com$/ },
      { name: 'T' }
    ]
  }).toArray()

  console.log('\n=== FAKE ADMIN ACCOUNTS FOUND:', fakeAdmins.length, '===')
  fakeAdmins.forEach(u => console.log(`  DELETE: ${u.email} | ${u.name}`))

  if (fakeAdmins.length > 0) {
    const ids = fakeAdmins.map(u => u._id)
    const result = await col.deleteMany({ _id: { $in: ids } })
    console.log(`✅ Deleted ${result.deletedCount} fake admin accounts`)
  }

  // ── 3. Fix any users with no role → set to student ──
  const noRole = await col.find({ role: { $exists: false } }).toArray()
  console.log('\n=== USERS WITH NO ROLE:', noRole.length, '===')
  noRole.forEach(u => console.log(`  ${u.email} | name: ${u.name}`))
  if (noRole.length > 0) {
    await col.updateMany(
      { role: { $exists: false } },
      { $set: { role: 'student' } }
    )
    console.log(`✅ Fixed ${noRole.length} users — role set to student`)
  }

  // ── 4. Final clean count ──
  const final = await col.find({}).toArray()
  const roles = {}
  final.forEach(u => { const r = u.role||'NO_ROLE'; roles[r] = (roles[r]||0)+1 })
  console.log('\n=== FINAL DB STATE ===')
  console.log('Total:', final.length)
  Object.entries(roles).forEach(([r,c]) => console.log(`  ${r}: ${c}`))

  console.log('\n=== ALL STUDENTS (FINAL) ===')
  final.filter(u => u.role === 'student').forEach((u,i) => {
    console.log(`[${i+1}] ${u.name} | ${u.email} | verified: ${u.emailVerified||u.verified||false} | created: ${u.createdAt?.toISOString?.()?.split('T')[0]||'N/A'}`)
  })

  await mongoose.disconnect()
}).catch(e => console.log('Error:', e.message))
NODEOF
