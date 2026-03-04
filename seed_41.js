require('dotenv').config();
const mongoose = require('mongoose');
mongoose.connect(process.env.MONGO_URI).then(async () => {
  console.log('DB connected');
  const Exam = require('./src/models/Exam');
  const r = await Exam.updateMany(
    { fullscreenForce: { $exists: false } },
    { $set: { fullscreenForce: false, fullscreenWarnings: 3, whitelistEnabled: false, accessWhitelist: [], maxAttempts: 1 } }
  );
  console.log(`✅ ${r.modifiedCount} exams updated`);
  const exams = await Exam.find({}).select('title fullscreenForce maxAttempts');
  exams.forEach(e => console.log(` - ${e.title} | fullscreen:${e.fullscreenForce} | maxAttempts:${e.maxAttempts}`));
  await mongoose.disconnect();
  console.log('✅ Seed done!');
}).catch(e => { console.error('❌', e.message); process.exit(1); });
