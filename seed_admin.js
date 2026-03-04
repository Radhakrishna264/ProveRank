const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

mongoose.connect(process.env.MONGO_URI).then(async () => {
  const db = mongoose.connection.db;
  
  // Check students collection mein admin hai?
  const stuAdmin = await db.collection('students').findOne({email: 'admin@proverank.com'});
  console.log('students mein admin?', stuAdmin ? 'YES - role:' + stuAdmin.role : 'NO');
  
  // Saare students ka email+role dekho
  const all = await db.collection('students').find({}).limit(5).toArray();
  console.log('Students sample:', all.map(s => ({email: s.email, role: s.role})));
  
  process.exit(0);
}).catch(e => { console.log('Error:', e.message); process.exit(1); });
