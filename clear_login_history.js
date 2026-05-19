const mongoose = require('mongoose');
require('dotenv').config();

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Connected');

  const result = await mongoose.connection.db
    .collection('students')
    .updateMany(
      {},
      {
        $set: {
          loginHistory: [],
          loginCount: 0
        }
      }
    );

  console.log('Users updated:', result.modifiedCount);
  await mongoose.disconnect();
}

run().catch(console.error);
