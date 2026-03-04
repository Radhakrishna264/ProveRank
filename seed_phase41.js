require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

async function seed() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('✅ Connected!');
  const db = mongoose.connection.db;

  // Student insert
  const hashedPass = await bcrypt.hash('ProveRank@123', 12);
  const student = await db.collection('students').insertOne({
    name: 'Test Student',
    email: 'student@proverank.com',
    password: hashedPass,
    role: 'student',
    isActive: true,
    createdAt: new Date()
  });

  // Exam insert
  const exam = await db.collection('exams').insertOne({
    title: 'Phase 4.1 Test Exam',
    status: 'published',
    duration: 200,
    totalQuestions: 180,
    correctMarks: 4,
    negativeMarks: 1,
    maxAttempts: 3,
    startTime: new Date(Date.now() - 60000),
    sections: ['Physics', 'Chemistry', 'Biology'],
    instructions: 'Read carefully. NEET pattern exam.',
    fullscreenForce: true,
    whitelist: [],
    createdAt: new Date()
  });

  console.log('\n✅ Student ID:', student.insertedId.toString());
  console.log('✅ Exam ID:', exam.insertedId.toString());
  console.log('\n🎉 Seed complete! Ab test run karo.');
  await mongoose.disconnect();
}

seed().catch(e => { console.error('❌', e.message); process.exit(1); });
