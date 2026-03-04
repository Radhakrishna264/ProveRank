require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./src/models/User');
async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  const r = await User.updateOne(
    { email: 'student@proverank.com' },
    { $set: { verified: true } }
  );
  console.log('verified fixed:', r.modifiedCount === 1 ? '✅ SUCCESS' : '❌ FAILED');
  const u = await User.findOne({ email: 'student@proverank.com' });
  console.log('Confirmed verified:', u.verified);
  await mongoose.disconnect();
}
run().catch(console.error);
