require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./src/models/User');

const MONGO_URI = process.env.MONGO_URI || process.env.MONGODB_URI;

async function run() {
  await mongoose.connect(MONGO_URI);
  console.log('MongoDB connected');

  // Purana test student delete karo (double-hashed wala)
  await User.deleteOne({ email: 'student1@test.com' });
  console.log('Old student deleted');

  // Plain password do — pre-save hook khud hash karega
  const student = await User.create({
    name: 'Test Student',
    email: 'student1@test.com',
    password: 'ProveRank@123',
    role: 'student',
    termsAccepted: true,
    isActive: true,
    verified: true
  });

  console.log('✅ Student created correctly!');
  console.log('   id:', student._id);
  console.log('   email:', student.email);
  await mongoose.disconnect();
}

run().catch(err => { console.error('Error:', err.message); process.exit(1); });
