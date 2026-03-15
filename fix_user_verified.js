const mongoose = require('mongoose')
const uri = process.env.MONGO_URI

mongoose.connect(uri).then(async () => {
  const result = await mongoose.connection.collection('students').updateMany(
    { emailVerified: true },
    { $set: { verified: true } }
  )
  console.log('✅ Fixed users:', result.modifiedCount)
  
  const user = await mongoose.connection.collection('students').findOne({ email: 'claudeaip06@gmail.com' })
  console.log('User verified:', user.verified, '| emailVerified:', user.emailVerified)
  mongoose.disconnect()
}).catch(err => { console.error(err.message); process.exit(1) })
