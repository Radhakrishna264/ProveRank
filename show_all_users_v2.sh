node << 'NODEOF'
const mongoose = require('./node_modules/mongoose')
require('dotenv').config()
mongoose.connect(process.env.MONGODB_URI || process.env.MONGO_URI).then(async () => {
  const col = mongoose.connection.db.collection('users')

  // NO date filter — show ALL users sorted by _id (newest last)
  const all = await col.find({}).sort({ _id: 1 }).toArray()
  
  console.log('=== TOTAL USERS IN DB:', all.length, '===\n')
  all.forEach((u,i) => {
    // _id has timestamp embedded
    const created = new Date(parseInt(u._id.toString().substring(0,8), 16)*1000)
      .toISOString().split('T')[0]
    console.log(`[${i+1}] ${u.email}`)
    console.log(`     role: ${u.role||'MISSING'} | verified: ${u.emailVerified||u.verified||false}`)
    console.log(`     created: ${created} | name: ${u.name||'—'}`)
  })

  const roles = {}
  all.forEach(u => { const r=u.role||'NO_ROLE'; roles[r]=(roles[r]||0)+1 })
  console.log('\n=== SUMMARY ===')
  Object.entries(roles).forEach(([r,c])=>console.log(` ${r}: ${c}`))
  console.log(' Total:', all.length)

}).catch(e => console.log('Error:', e.message))
NODEOF
