require('dotenv').config();
const mongoose = require('mongoose');
const Exam = require('./src/models/Exam');
async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  const all = await Exam.find({}, '_id title fullscreenForce');
  console.log('Total exams:', all.length);
  all.forEach(e => console.log(e._id, e.title, '| fullscreenForce:', e.fullscreenForce));
  const r = await Exam.updateMany({}, { $set: { fullscreenForce: true, fullscreenWarnings: 0 } });
  console.log('Updated:', r.modifiedCount);
  await mongoose.disconnect();
}
run().catch(console.error);
