const mongoose = require('mongoose')
const bcrypt = require('bcrypt')
const uri = process.env.MONGO_URI

mongoose.connect(uri).then(async () => {
  const user = await mongoose.connection.collection('students').findOne({ email: 'claudeaip06@gmail.com' })
  console.log('=== USER DATA ===')
  console.log('verified:', user.verified)
  console.log('emailVerified:', user.emailVerified)
  console.log('banned:', user.banned)
  console.log('role:', user.role)
  console.log('password hash exists:', !!user.password)
  
  // Test password - apna actual password yahan likho
  const testPass = 'Test@12345'
  const match = await bcrypt.compare(testPass, user.password)
  console.log('Password match (Test@12345):', match)
  
  mongoose.disconnect()
}).catch(err => { console.error(err.message); process.exit(1) })
