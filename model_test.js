const WS = process.env.HOME + '/workspace';
const mongoose = require(WS + '/node_modules/mongoose');
const dotenv = require(WS + '/node_modules/dotenv');
dotenv.config({ path: WS + '/.env' });

mongoose.connect(process.env.MONGO_URI).then(async () => {
  console.log('DB Connected');

  // 1. Exam model check
  const Exam = require(WS + '/src/models/Exam');
  console.log('\nExam collection name:', Exam.collection.name);

  const exam = await Exam.findById('69a695892217ac6201221bfa');
  console.log('Exam.findById result:', exam ? 'FOUND ✅ title:'+exam.title : 'NULL ❌');

  // 2. Attempt model check  
  const Attempt = require(WS + '/src/models/Attempt');
  console.log('\nAttempt collection name:', Attempt.collection.name);

  const attempt = await Attempt.findById('69a84803bf3cd6ffdab84326');
  console.log('Attempt.findById result:', attempt ? 'FOUND ✅ status:'+attempt.status : 'NULL ❌');

  // 3. Direct collection query
  const db = mongoose.connection.db;
  const rawExam = await db.collection('exams').findOne({});
  console.log('\nRaw exams collection first doc _id:', rawExam?._id?.toString());

  const rawAttempt = await db.collection('attempts').findOne({});
  console.log('Raw attempts collection first doc _id:', rawAttempt?._id?.toString());

  // 4. User model check
  const User = require(WS + '/src/models/User');
  console.log('\nUser collection name:', User.collection.name);
  const user = await User.findOne({ email: 'student@proverank.com' });
  console.log('Student found:', user ? 'YES ✅ termsAccepted:'+user.termsAccepted : 'NO ❌');

  await mongoose.disconnect();
}).catch(e => console.log('Error:', e.message));
