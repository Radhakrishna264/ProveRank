require('dotenv').config();
const mongoose = require('mongoose');

async function check() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('✅ Connected!\n');
  const db = mongoose.connection.db;

  const students = await db.collection('students').find({}).limit(3).toArray();
  const exams = await db.collection('exams').find({}).limit(3).toArray();
  const attempts = await db.collection('attempts').find({}).limit(3).toArray();

  console.log('👤 STUDENTS found:', students.length);
  students.forEach(s => console.log('  -', s._id, '|', s.name || s.email || 'no name'));

  console.log('\n📝 EXAMS found:', exams.length);
  exams.forEach(e => console.log('  -', e._id, '|', e.title, '| status:', e.status));

  console.log('\n📋 ATTEMPTS found:', attempts.length);
  attempts.forEach(a => console.log('  -', a._id, '| exam:', a.exam, '| student:', a.student));

  await mongoose.disconnect();
}

check().catch(e => { console.error(e.message); process.exit(1); });
