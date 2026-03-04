require('dotenv').config();
const mongoose = require('mongoose');
mongoose.connect(process.env.MONGO_URI).then(async () => {
  const bcrypt = require('bcrypt');
  const s = await mongoose.connection.db.collection('students').findOne({});
  console.log('Email:', s.email);
  const m1 = await bcrypt.compare('ProveRank@123', s.password);
  const m2 = await bcrypt.compare('ProveRank@SuperAdmin123', s.password);
  console.log('ProveRank@123 match:', m1);
  console.log('SuperAdmin pass match:', m2);
  await mongoose.disconnect();
}).catch(e => console.error(e.message));
