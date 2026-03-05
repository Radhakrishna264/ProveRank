require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const User = require('./src/models/User');

const MONGO_URI = process.env.MONGO_URI || process.env.MONGODB_URI;

async function run() {
  await mongoose.connect(MONGO_URI);
  console.log('MongoDB connected');

  const existing = await User.findOne({ email: 'student1@test.com' });
  if (existing) {
    console.log('✅ Already exists via User model!');
    console.log('   id:', existing._id);
    await mongoose.disconnect();
    return;
  }

  const hash = await bcrypt.hash('ProveRank@123', 12);
  const student = await User.create({
    name: 'Test Student',
    email: 'student1@test.com',
    password: hash,
    role: 'student',
    termsAccepted: true,
    isActive: true
  });

  console.log('✅ Student created via User model!');
  console.log('   id:', student._id);
  console.log('   email:', student.email);
  await mongoose.disconnect();
}

run().catch(err => { console.error('Error:', err.message); process.exit(1); });
