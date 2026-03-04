require('dotenv').config();
const mongoose = require('mongoose');
mongoose.connect(process.env.MONGO_URI).then(async () => {

  // Fix 1: verified=true karo
  const r = await mongoose.connection.db
    .collection('students')
    .updateMany({}, { $set: { verified: true } });
  console.log('✅ verified=true set on', r.modifiedCount, 'students');

  // Fix 2: User model ka collection check karo
  const fs = require('fs');
  const model = fs.readFileSync('./src/models/User.js', 'utf8');
  console.log('\nUser model collection line:');
  const lines = model.split('\n').filter(l => l.includes('collection') || l.includes('mongoose.model'));
  lines.forEach(l => console.log(l.trim()));

  await mongoose.disconnect();
}).catch(e => console.error(e.message));
