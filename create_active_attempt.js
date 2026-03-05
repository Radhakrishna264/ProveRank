const mongoose = require('mongoose');
const MONGO_URI = process.env.MONGO_URI;

async function main() {
  await mongoose.connect(MONGO_URI);
  console.log('MongoDB Connected ✅');

  const User = mongoose.model('User', new mongoose.Schema({}, { strict: false }), 'students');
  const Exam = mongoose.model('Exam', new mongoose.Schema({}, { strict: false }), 'exams');
  const Attempt = mongoose.model('Attempt', new mongoose.Schema({}, { strict: false }), 'attempts');

  const student = await User.findOne({ role: 'student' });
  if (!student) { console.log('❌ Student nahi mila!'); process.exit(1); }
  console.log('Student:', student.email);

  const exam = await Exam.findOne();
  if (!exam) { console.log('❌ Exam nahi mili!'); process.exit(1); }
  console.log('Exam:', exam.title);

  const attempt = await Attempt.create({
    examId: exam._id,
    studentId: student._id,
    status: 'active',
    ipAddress: '127.0.0.1',
    startedAt: new Date(),
    answers: [],
    totalScore: 0,
    sections: exam.sections || []
  });

  console.log('✅ Active attempt created!');
  console.log('AttemptId:', attempt._id.toString());
  await mongoose.disconnect();
}

main().catch(e => { console.error('❌', e.message); process.exit(1); });
