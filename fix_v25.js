const path = require('path');
const fs = require('fs');

const WS = process.env.HOME + '/workspace';

// --- FIX 1: exam_patch.js mein await fix ---
let patch = fs.readFileSync(WS + '/src/routes/exam_patch.js', 'utf8');

// Line 57 type: const exam = Exam.findById(...) -- no await
patch = patch.replace(
  /const exam = Exam\.findById\(req\.params\.examId\)\s*;/,
  'const exam = await Exam.findById(req.params.examId);'
);

fs.writeFileSync(WS + '/src/routes/exam_patch.js', patch);
console.log('FIX 1 DONE: await added in exam_patch.js accept-terms');

// --- FIX 2: Exam model ka collection name check ---
const examModelPath = WS + '/src/models/Exam.js';
const examModel = fs.readFileSync(examModelPath, 'utf8');
console.log('\nExam model mongoose.model line:');
const modelLine = examModel.split('\n').find(l => l.includes('mongoose.model'));
console.log(modelLine);

// --- FIX 3: ObjectId safe conversion in exam.js ---
let examJs = fs.readFileSync(WS + '/src/routes/exam.js', 'utf8');

// start-attempt mein findById ke saath mongoose ObjectId wrap
if (!examJs.includes('mongoose.Types.ObjectId(req.params.examId)')) {
  examJs = examJs.replace(
    /Exam\.findById\(req\.params\.examId\)/g,
    'Exam.findById(new mongoose.Types.ObjectId(req.params.examId))'
  );
  fs.writeFileSync(WS + '/src/routes/exam.js', examJs);
  console.log('FIX 3 DONE: ObjectId wrap added in exam.js');
} else {
  console.log('FIX 3: Already has ObjectId wrap');
}

// --- VERIFY: DB mein exam hai ya nahi ---
const mongoose = require(WS + '/node_modules/mongoose');
const dotenv = require(WS + '/node_modules/dotenv');
dotenv.config({ path: WS + '/.env' });

mongoose.connect(process.env.MONGO_URI).then(async () => {
  console.log('\n--- DB VERIFY ---');
  const db = mongoose.connection.db;
  const exams = await db.collection('exams').find({}).toArray();
  console.log('Total exams in DB:', exams.length);
  exams.forEach(e => {
    console.log('Exam _id:', e._id.toString(), '| title:', e.title);
  });

  // Check karo exact ID match
  const { ObjectId } = mongoose.Types;
  const found = await db.collection('exams').findOne({ 
    _id: new ObjectId('69a695892217ac6201221bfa') 
  });
  console.log('Exact ID search result:', found ? 'FOUND ✅' : 'NOT FOUND ❌');
  if (found) console.log('Exam title:', found.title);

  await mongoose.disconnect();
  console.log('\nAll fixes applied. Now run the test!');
}).catch(err => {
  console.log('DB Error:', err.message);
  process.exit(1);
});
