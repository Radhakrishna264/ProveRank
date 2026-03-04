require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const User = require('./src/models/User');
async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  const hashed = await bcrypt.hash('ProveRank@123', 12);
  const r = await User.updateOne(
    { email: 'student@proverank.com' },
    { $set: { password: hashed } }
  );
  console.log('Password fixed:', r.modifiedCount === 1 ? 'SUCCESS' : 'NOT FOUND');
  await mongoose.disconnect();
}
run().catch(console.error);
