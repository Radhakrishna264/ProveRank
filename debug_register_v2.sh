node << 'NODEOF'
const mongoose = require('./node_modules/mongoose')
require('dotenv').config()
mongoose.connect(process.env.MONGODB_URI || process.env.MONGO_URI).then(async () => {
  const col = mongoose.connection.db.collection('users')

  // Check today's / recent registrations (last 24 hours)
  const recent = await col.find({
    createdAt: { $gte: new Date(Date.now() - 24*60*60*1000) }
  }).toArray()
  console.log('=== CREATED LAST 24 HOURS:', recent.length)
  recent.forEach(u => console.log(' ', u.email, '|', u.role, '| verified:', u.emailVerified||u.verified))

  // Check last 7 days
  const week = await col.find({
    createdAt: { $gte: new Date(Date.now() - 7*24*60*60*1000) }
  }).toArray()
  console.log('\n=== CREATED LAST 7 DAYS:', week.length)
  week.forEach(u => console.log(' ', u.email, '| created:', u.createdAt?.toISOString?.()?.split('T')[0]))

  // Try inserting a test user to verify insertOne works
  console.log('\n=== TESTING insertOne...')
  try {
    const testEmail = 'debug_test_' + Date.now() + '@test.com'
    await col.insertOne({
      name: 'Debug Test', email: testEmail, password: 'testhash',
      role: 'student', verified: false, emailVerified: false,
      emailVerifyOTP: '123456', createdAt: new Date()
    })
    console.log('✅ insertOne WORKS')
    // Clean up
    await col.deleteOne({ email: testEmail })
    console.log('✅ Test user cleaned up')
  } catch(e) {
    console.log('❌ insertOne FAILED:', e.message)
  }

  // Check if unique index on email causing silent fail
  const indexes = await col.indexes()
  console.log('\n=== COLLECTION INDEXES:')
  indexes.forEach(idx => console.log(' ', JSON.stringify(idx.key), '| unique:', idx.unique||false))

  await mongoose.disconnect()
}).catch(e => console.log('Error:', e.message))
NODEOF
