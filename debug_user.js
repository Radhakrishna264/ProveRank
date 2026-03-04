require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./src/models/User');
async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  const user = await User.findOne({ email: 'student@proverank.com' });
  console.log('Full user fields:', JSON.stringify({
    email: user.email,
    role: user.role,
    isVerified: user.isVerified,
    isActive: user.isActive,
    isEmailVerified: user.isEmailVerified,
    status: user.status,
    otp: user.otp,
    otpExpiry: user.otpExpiry
  }, null, 2));
  
  // Fix all flags at once
  await User.updateOne(
    { email: 'student@proverank.com' },
    { $set: {
      isVerified: true,
      isActive: true,
      isEmailVerified: true,
      status: 'active',
      otp: null,
      otpExpiry: null
    }}
  );
  console.log('✅ All flags fixed!');
  await mongoose.disconnect();
}
run().catch(console.error);
