require('dotenv').config();
const mongoose = require('mongoose');
const Exam = require('./src/models/Exam');
async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  const r = await Exam.updateMany(
    { fullscreenForce: { $exists: false } },
    { $set: { fullscreenForce: true, fullscreenWarnings: 0 } }
  );
  console.log('Exams updated:', r.modifiedCount);
  await mongoose.disconnect();
}
run().catch(console.error);
