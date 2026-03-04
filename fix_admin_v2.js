const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
require('dotenv').config();
const MONGO_URI = process.env.MONGODB_URI || process.env.MONGO_URI;
async function diagnose() {
  console.log('=== DIAGNOSTIC V2 ===');
  await mongoose.connect(MONGO_URI);
  console.log('MongoDB Connected');
  const db = mongoose.connection.db;
  const students = db.collection('students');
  const admin = await students.findOne({ email: 'admin@proverank.com' });
  if (!admin) {
    console.log('Admin NOT FOUND - Creating...');
    const hash = await bcrypt.hash('ProveRank@SuperAdmin123', 12);
    await students.insertOne({ name: 'Super Admin', email: 'admin@proverank.com', password: hash, role: 'superadmin', verified: true, banned: false, adminFrozen: false, phone: '9999999999', createdAt: new Date(), updatedAt: new Date() });
    console.log('Admin created!');
  } else {
    console.log('Admin found | role:', admin.role, '| verified:', admin.verified);
    const match = await bcrypt.compare('ProveRank@SuperAdmin123', admin.password);
    console.log('bcrypt result:', match);
    if (!match) {
      const newHash = await bcrypt.hash('ProveRank@SuperAdmin123', 12);
      await students.updateOne({ email: 'admin@proverank.com' }, { $set: { password: newHash, verified: true, banned: false, adminFrozen: false } });
      console.log('Password fixed!');
    } else {
      console.log('Password OK - bug is in auth.js code');
    }
  }
  await mongoose.disconnect();
  console.log('=== DONE ===');
}
diagnose().catch(e => console.error('FATAL:', e.message));
