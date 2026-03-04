const mongoose = require('mongoose');
mongoose.connect(process.env.MONGO_URI).then(async () => {
  const exams = await mongoose.connection.collection('exams').find({}).project({title:1, maxAttempts:1, reAttemptLimit:1}).toArray();
  console.log(JSON.stringify(exams, null, 2));
  mongoose.disconnect();
});
