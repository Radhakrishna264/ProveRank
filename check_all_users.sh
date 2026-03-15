node << 'NODEOF'
const mongoose = require('./node_modules/mongoose')
require('dotenv').config()
const MONGO = process.env.MONGODB_URI || process.env.MONGO_URI
mongoose.connect(MONGO).then(async () => {
  const db = mongoose.connection.db

  // ALL users — no role filter
  const all = await db.collection('users').find({}).toArray()
  console.log('=== TOTAL USERS IN DB:', all.length, '===\n')
  all.forEach((u,i) => {
    console.log(`[${i+1}] ${u.name} | ${u.email} | role: ${u.role||'MISSING'} | verified: ${u.emailVerified||u.verified||false} | created: ${u.createdAt?.toISOString?.()?.split('T')[0]||'N/A'}`)
  })

  // Stats
  const roles = {}
  all.forEach(u => { const r = u.role||'NO_ROLE'; roles[r] = (roles[r]||0)+1 })
  console.log('\n=== ROLE BREAKDOWN ===')
  Object.entries(roles).forEach(([r,c]) => console.log(`  ${r}: ${c}`))

  await mongoose.disconnect()
}).catch(e => console.log('Error:', e.message))
NODEOF
