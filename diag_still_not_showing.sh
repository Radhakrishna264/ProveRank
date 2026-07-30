#!/bin/bash
cd ~/workspace

cat > diag_check.js << 'EOF'
const mongoose = require('mongoose');
require('dotenv').config();
mongoose.connect(process.env.MONGO_URI).then(async () => {
  const Exam = require('./src/models/Exam');
  const Batch = require('./src/models/Batch');
  const User = require('./src/models/User');

  console.log('=== 1. Dropper 2.0 batch — current state ===');
  const batch = await Batch.findOne({ name: { $regex: 'Dropper 2.0', $options: 'i' } })
    .select('_id name exams students').lean();
  console.log(JSON.stringify(batch, null, 2));

  if (batch) {
    console.log('\n=== 2. Exams inside batch.exams[] — current batch/status field ===');
    const exams = await Exam.find({ _id: { $in: batch.exams || [] } })
      .select('title status batch multiBatch testSeriesId').lean();
    console.log(JSON.stringify(exams, null, 2));
  }

  console.log('\n=== 3. Student claudeaip06@gmail.com — enrollment format ===');
  const student = await User.findOne({ email: 'claudeaip06@gmail.com' })
    .select('_id name email batch batches enrolledBatchesMeta').lean();
  console.log(JSON.stringify(student, null, 2));

  process.exit(0);
}).catch(e => { console.error('ERROR:', e.message); process.exit(1); });
EOF
node diag_check.js
rm diag_check.js
