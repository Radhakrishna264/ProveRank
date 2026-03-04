const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

mongoose.connect(process.env.MONGO_URI).then(async () => {
  const db = mongoose.connection.db;
  
  // Pehle check karo exist toh nahi karta
  const existing = await db.collection('students').findOne({email: 'admin@proverank.com'});
  if (existing) {
    console.log('Admin already exists! Role:', existing.role);
    process.exit(0);
  }
  
  const hash = await bcrypt.hash('ProveRank@SuperAdmin123', 12);
  
  await db.collection('students').insertOne({
    name: 'Super Admin',
    email: 'admin@proverank.com',
    password: hash,
    role: 'superadmin',
    isActive: true,
    termsAccepted: true,
    createdAt: new Date(),
    updatedAt: new Date()
  });
  
  console.log('✅ SuperAdmin created successfully!');
  console.log('Email: admin@proverank.com');
  console.log('Password: ProveRank@SuperAdmin123');
  process.exit(0);
}).catch(e => { console.log('❌ Error:', e.message); process.exit(1); });
