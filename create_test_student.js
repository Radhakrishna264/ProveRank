const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
require('dotenv').config();
const MONGO_URI = process.env.MONGODB_URI || process.env.MONGO_URI;
async function run() {
  await mongoose.connect(MONGO_URI);
  const db = mongoose.connection.db;
  const students = db.collection('students');
  const existing = await students.findOne({ email: 'student@proverank.com' });
  if (existing) {
    console.log('Student already exists! ID:', existing._id.toString());
  } else {
    const hash = await bcrypt.hash('ProveRank@123', 12);
    const result = await students.insertOne({
      name: 'Test Student',
      email: 'student@proverank.com',
      password: hash,
      role: 'student',
      verified: true,
      banned: false,
      adminFrozen: false,
      phone: '8888888888',
      createdAt: new Date(),
      updatedAt: new Date()
    });
    console.log('Student created! ID:', result.insertedId.toString());
  }
  await mongoose.disconnect();
  console.log('Done!');
}
run().catch(e => console.error('Error:', e.message));
