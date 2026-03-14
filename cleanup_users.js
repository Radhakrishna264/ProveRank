const mongoose = require('mongoose')
const uri = process.env.MONGO_URI

mongoose.connect(uri).then(async () => {
  const result = await mongoose.connection.collection('students').deleteMany({ role: 'student' })
  console.log('✅ Deleted students:', result.deletedCount)
  mongoose.disconnect()
}).catch(err => {
  console.error('❌ Error:', err.message)
  process.exit(1)
})
