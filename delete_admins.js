const mongoose = require('mongoose');
require('dotenv').config();

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Connected');

  const result = await mongoose.connection.db
    .collection('students')
    .deleteMany({
      role: 'admin',
      email: { $ne: 'testadmin@proverank.com' }
    });

  console.log('Deleted admins:', result.deletedCount);
  await mongoose.disconnect();
}

run().catch(console.error);
