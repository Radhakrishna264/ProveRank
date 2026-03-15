const mongoose = require('mongoose')
const bcrypt = require('bcrypt')
const uri = process.env.MONGO_URI

mongoose.connect(uri).then(async () => {
  const newPass = 'ProveRank@123'
  const hash = await bcrypt.hash(newPass, 12)
  
  const result = await mongoose.connection.collection('students').updateOne(
    { email: 'claudeaip06@gmail.com' },
    { $set: { password: hash } }
  )
  console.log('✅ Password reset done:', result.modifiedCount)
  console.log('New password: ProveRank@123')
  mongoose.disconnect()
}).catch(err => { console.error(err.message); process.exit(1) })
