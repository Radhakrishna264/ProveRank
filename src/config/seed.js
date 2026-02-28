require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const User = require('../models/User');

mongoose.connect(process.env.MONGODB_URI).then(async () => {
  const exists = await User.findOne({ role: 'superadmin' });
  if (exists) { console.log('SuperAdmin already exists!'); process.exit(); }
  const password = await bcrypt.hash('ProveRank@SuperAdmin123', 12);
  await User.create({ name: 'SuperAdmin', email: 'admin@proverank.com', password, role: 'superadmin', verified: true });
  console.log('SuperAdmin created! Email: admin@proverank.com');
  process.exit();
});
