node << 'NODEOF'
const mongoose = require('./node_modules/mongoose')
require('dotenv').config()
mongoose.connect(process.env.MONGODB_URI || process.env.MONGO_URI).then(async () => {
  const col = mongoose.connection.db.collection('users')

  // Delete ALL role:admin accounts (fake)
  const fakeAdmins = await col.find({ role: 'admin' }).toArray()
  console.log('Fake admins to delete:')
  fakeAdmins.forEach(u => console.log(' DELETE:', u.email))
  if (fakeAdmins.length > 0) {
    const r = await col.deleteMany({ role: 'admin' })
    console.log('✅ Deleted:', r.deletedCount)
  }

  // Show ALL unverified - these are new registrations pending OTP
  const unverified = await col.find({ $or:[{emailVerified:false},{verified:false},{emailVerified:{$exists:false}}] }).toArray()
  console.log('\n=== UNVERIFIED (new registrations):', unverified.length)
  unverified.forEach(u => console.log(' ', u.email, '| role:', u.role||'MISSING', '| OTP:', u.emailVerifyOTP||'null'))

  // Final state
  const all = await col.find({}).toArray()
  const roles = {}
  all.forEach(u => { const r=u.role||'NO_ROLE'; roles[r]=(roles[r]||0)+1 })
  console.log('\n=== FINAL:', all.length, 'users ===')
  Object.entries(roles).forEach(([r,c])=>console.log(' ',r,':',c))
  all.forEach((u,i)=>console.log(`[${i+1}]`,u.email,'|',u.role||'NO_ROLE','| verified:',u.emailVerified||u.verified||false))

  await mongoose.disconnect()
}).catch(e=>console.log('Error:',e.message))
NODEOF
