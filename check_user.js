const mongoose = require('mongoose')
const uri = process.env.MONGO_URI

mongoose.connect(uri).then(async () => {
  const user = await mongoose.connection.collection('students').findOne({ email: 'claudeaip06@gmail.com' })
  console.log('User:', JSON.stringify(user, null, 2))
  mongoose.disconnect()
}).catch(err => { console.error(err.message); process.exit(1) })
