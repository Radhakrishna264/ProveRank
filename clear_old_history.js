const mongoose = require('mongoose');
require('dotenv').config();
async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  await mongoose.connection.db.collection('students')
    .updateMany({}, { $set: { loginHistory: [], loginCount: 0 } });
  console.log('✅ Cleared');
  await mongoose.disconnect();
}
run().catch(console.error);
