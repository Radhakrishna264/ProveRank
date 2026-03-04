const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

mongoose.connect(process.env.MONGO_URI).then(async () => {
  const newHash = await bcrypt.hash('ProveRank@SuperAdmin123', 12);
  const db = mongoose.connection.db;
  
  await db.collection('students').updateOne(
    { email: 'admin@proverank.com' },
    { $set: { 
      password: newHash,
      verified: true,
      banned: false,
      isActive: true,
      loginHistory: [],
      phone: '9999999999'
    }}
  );
  
  // Verify
  const admin = await db.collection('students').findOne({email: 'admin@proverank.com'});
  const match = await bcrypt.compare('ProveRank@SuperAdmin123', admin.password);
  console.log('Password match after update:', match);
  console.log('Verified:', admin.verified);
  console.log('Banned:', admin.banned);
  process.exit(0);
}).catch(e => { console.log('Error:', e.message); process.exit(1); });
