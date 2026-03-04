require('dotenv').config();
const mongoose = require('mongoose');
mongoose.connect(process.env.MONGO_URI).then(async () => {
  const r = await mongoose.connection.db.collection('students').updateMany(
    { isActive: { $ne: true } },
    { $set: { isActive: true } }
  );
  console.log('✅ Students activated:', r.modifiedCount);
  const s = await mongoose.connection.db.collection('students').findOne({});
  console.log('Email:', s.email, '| isActive:', s.isActive);
  await mongoose.disconnect();
}).catch(e => console.error(e.message));
