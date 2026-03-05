const WS = process.env.HOME + '/workspace';
const mongoose = require(WS + '/node_modules/mongoose');
const dotenv = require(WS + '/node_modules/dotenv');
dotenv.config({ path: WS + '/.env' });

mongoose.connect(process.env.MONGO_URI).then(async () => {
  const db = mongoose.connection.db;

  // Server ke actual exams
  const exams = await db.collection('exams').find({}).toArray();
  console.log('=== Server DB Exams ===');
  exams.forEach(e => console.log('ID:', e._id.toString(), '| Title:', e.title));

  const EXAM_ID = exams[0]._id.toString();
  console.log('\nCORRECT Exam ID:', EXAM_ID);

  // Students
  const students = await db.collection('students').find({}).toArray();
  console.log('\n=== Students ===');
  students.forEach(s => console.log('ID:', s._id.toString(), '| email:', s.email, '| termsAccepted:', s.termsAccepted));

  // termsAccepted fix
  await db.collection('students').updateMany({}, { $set: { termsAccepted: true } });
  console.log('termsAccepted → true for all students ✅');

  // Attempts
  const attempts = await db.collection('attempts').find({}).toArray();
  console.log('\n=== Attempts ===');
  attempts.forEach(a => console.log('ID:', a._id.toString(), '| status:', a.status, '| examId:', (a.examId||a.exam||'').toString()));

  const ATTEMPT_ID = attempts.find(a => a.status === 'active')?._id.toString() || attempts[0]?._id.toString();
  console.log('\nCORRECT Attempt ID:', ATTEMPT_ID);

  // test_phase_4_2.js mein IDs update karo
  let test = require('fs').readFileSync(WS + '/test_phase_4_2.js', 'utf8');

  // Exam ID replace
  test = test.replace(
    /69a695892217ac6201221bfa/g,
    EXAM_ID
  );

  // Attempt ID replace (hardcoded jo bhi hai)
  if (ATTEMPT_ID) {
    test = test.replace(
      /69a84803bf3cd6ffdab84326/g,
      ATTEMPT_ID
    );
  }

  require('fs').writeFileSync(WS + '/test_phase_4_2.js', test);
  console.log('\ntest_phase_4_2.js updated with correct IDs ✅');

  await mongoose.disconnect();
}).catch(e => console.log('Error:', e.message));
