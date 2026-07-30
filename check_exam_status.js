const mongoose = require('mongoose');
require('dotenv').config();
mongoose.connect(process.env.MONGO_URI).then(async () => {
  const Exam = require('./src/models/Exam');
  const exams = await Exam.find({ title: { $regex: 'NEET Full Mock Test 1', $options: 'i' } })
    .select('title status batch multiBatch testSeriesId schedule').lean();
  console.log(JSON.stringify(exams, null, 2));
  process.exit(0);
}).catch(e => { console.log('ERROR:', e.message); process.exit(1); });
