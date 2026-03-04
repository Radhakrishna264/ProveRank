const mongoose = require('mongoose');
mongoose.connect(process.env.MONGO_URI).then(async () => {
  const result = await mongoose.connection.collection('exams').updateMany(
    {},
    { $set: { maxAttempts: 5, reAttemptLimit: 5 } }
  );
  console.log('Updated exams:', result.modifiedCount);
  mongoose.disconnect();
});
