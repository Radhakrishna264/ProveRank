const fs = require('fs');
const WS = process.env.HOME + '/workspace';

console.log('\n=== DIAGNOSIS ===\n');

// 1. exam.js mein start-attempt route dhundo
const examJs = fs.readFileSync(WS + '/src/routes/exam.js', 'utf8');
const lines = examJs.split('\n');
lines.forEach((l, i) => {
  if (l.includes('start-attempt')) console.log('exam.js line ' + (i+1) + ': ' + l.trim());
});

// 2. attemptRoutes mein saare routes
const attemptJs = fs.readFileSync(WS + '/src/routes/attemptRoutes.js', 'utf8');
const alines = attemptJs.split('\n');
console.log('\nAttemptRoutes routes:');
alines.forEach((l, i) => {
  if (l.includes('router.')) console.log('  line ' + (i+1) + ': ' + l.trim());
});

// 3. examFeatures mein /:id routes (conflict check)
const featJs = fs.readFileSync(WS + '/src/routes/examFeatures.js', 'utf8');
console.log('\nexamFeatures /:id routes:');
featJs.split('\n').forEach((l, i) => {
  if (l.match(/router\.(get|post|put|patch|delete)\s*\(\s*['"]\/:id/)) {
    console.log('  CONFLICT RISK line ' + (i+1) + ': ' + l.trim());
  }
});

// 4. index.js mount order
const indexJs = fs.readFileSync(WS + '/src/index.js', 'utf8');
console.log('\nMount order /api/exams:');
indexJs.split('\n').forEach((l, i) => {
  if (l.includes('/api/exams') || l.includes('/api/attempts')) {
    console.log('  line ' + (i+1) + ': ' + l.trim());
  }
});

console.log('\n=== FIXES ===\n');

// FIX A: index.js mein examRoutes ko PEHLE mount karo (examFeatures se upar)
let idx = fs.readFileSync(WS + '/src/index.js', 'utf8');

// Check karo current order
const featLine = idx.match(/app\.use\(['"](\/api\/exams)['"]\s*,\s*examFeaturesRoutes\)/);
const examLine = idx.match(/app\.use\(['"](\/api\/exams)['"]\s*,\s*examRoutes\)/);

if (featLine && examLine) {
  const featPos = idx.indexOf(featLine[0]);
  const examPos = idx.indexOf(examLine[0]);
  
  if (featPos < examPos) {
    console.log('PROBLEM FOUND: examFeaturesRoutes examRoutes se PEHLE mount hai');
    console.log('FIX A: examRoutes ko pehle move kar raha hoon...');
    
    // examRoutes line remove karo
    const examUseLine = `app.use('/api/exams', examRoutes);`;
    const featUseLine = `app.use('/api/exams', examFeaturesRoutes);`;
    
    // examRoutes wali line hata ke features se pehle daalo
    idx = idx.replace('\n' + examUseLine, '');
    idx = idx.replace(featUseLine, examUseLine + '\n' + featUseLine);
    
    fs.writeFileSync(WS + '/src/index.js', idx);
    console.log('FIX A DONE: examRoutes ab pehle mount hoga');
  } else {
    console.log('Mount order OK - examRoutes pehle hai');
  }
}

// FIX B: exam_patch.js - saare Exam.findById mein await ensure karo
let patch = fs.readFileSync(WS + '/src/routes/exam_patch.js', 'utf8');
const fixed = patch.replace(
  /(?<!await\s)Exam\.findById\(/g,
  'await Exam.findById('
);
if (fixed !== patch) {
  fs.writeFileSync(WS + '/src/routes/exam_patch.js', fixed);
  console.log('FIX B DONE: All Exam.findById now have await');
} else {
  console.log('FIX B: await already present');
}

// FIX C: DB se fresh attemptId lo
const mongoose = require(WS + '/node_modules/mongoose');
const dotenv = require(WS + '/node_modules/dotenv');
dotenv.config({ path: WS + '/.env' });

mongoose.connect(process.env.MONGO_URI).then(async () => {
  const db = mongoose.connection.db;
  
  const attempts = await db.collection('attempts').find({}).toArray();
  console.log('\nAttempts in DB:', attempts.length);
  attempts.forEach(a => {
    console.log('  _id:', a._id.toString(), '| status:', a.status, '| examId:', a.examId || a.exam);
  });
  
  // Fresh attempt check
  const activeAttempt = attempts.find(a => a.status === 'active' || a.status === 'waiting');
  if (activeAttempt) {
    console.log('\nFRESH ATTEMPT ID:', activeAttempt._id.toString());
    fs.writeFileSync('/tmp/attempt_id.txt', activeAttempt._id.toString());
    console.log('Saved to /tmp/attempt_id.txt');
  } else {
    console.log('\nNo active attempt in DB - start-attempt API se banegi');
    fs.writeFileSync('/tmp/attempt_id.txt', '');
  }
  
  await mongoose.disconnect();
  console.log('\n=== Run karo: bash ~/workspace/run_test_v26.sh ===');
}).catch(e => console.log('DB Error:', e.message));
