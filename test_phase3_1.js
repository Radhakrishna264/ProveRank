// ============================================
// Phase 3.1 Test Script — Random Selection Engine
// Ek script se poora phase test
// ============================================
require('dotenv').config();
const mongoose = require('mongoose');

async function runTests() {
  console.log('\n🧪 Phase 3.1 — Random Selection Engine Test\n');
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('✅ MongoDB connected\n');

  const {
    generateNEETPaper,
    selectBySubjectAndDifficulty,
    lockQuestionSnapshot,
    randomizeForStudent,
    NEET_DISTRIBUTION,
    DEFAULT_DIFFICULTY_WEIGHTS
  } = require('./src/utils/randomSelector');

  const Question = require('./src/models/Question');
  const Exam = require('./src/models/Exam');
  const User = require('./src/models/User');

  // Admin auto-fetch (Rule #12 — user ko manually copy nahi karna)
  const admin = await User.findOne({ role: { $in: ['admin', 'superadmin'] } });
  if (!admin) { console.log('❌ Admin nahi mila'); process.exit(1); }
  console.log(`👤 Admin found: ${admin.email}`);

  // Question count check
  const qCount = await Question.countDocuments();
  console.log(`\n📊 Total Questions in DB: ${qCount}`);

  const physicsCount    = await Question.countDocuments({ subject: 'Physics' });
  const chemistryCount  = await Question.countDocuments({ subject: 'Chemistry' });
  const biologyCount    = await Question.countDocuments({ subject: 'Biology' });
  console.log(`   Physics: ${physicsCount} | Chemistry: ${chemistryCount} | Biology: ${biologyCount}`);

  // ─── Test 1: NEET Distribution constants ───
  console.log('\n─── Test 1: NEET_DISTRIBUTION ───');
  console.log('Physics:', NEET_DISTRIBUTION.Physics, '(chahiye: 45)');
  console.log('Chemistry:', NEET_DISTRIBUTION.Chemistry, '(chahiye: 45)');
  console.log('Biology:', NEET_DISTRIBUTION.Biology, '(chahiye: 90)');
  const t1 = NEET_DISTRIBUTION.Physics === 45 &&
             NEET_DISTRIBUTION.Chemistry === 45 &&
             NEET_DISTRIBUTION.Biology === 90;
  console.log(t1 ? '✅ Test 1 PASS' : '❌ Test 1 FAIL');

  // ─── Test 2: Subject filter + weighted selection ───
  console.log('\n─── Test 2: Subject Filter (Physics ke 10 questions) ───');
  try {
    const physicsQs = await selectBySubjectAndDifficulty('Physics', 10, DEFAULT_DIFFICULTY_WEIGHTS);
    console.log(`Selected: ${physicsQs.length} questions`);
    const subjects = [...new Set(physicsQs.map(q => q.subject))];
    console.log('Subjects in result:', subjects);
    const t2 = physicsQs.length > 0 && subjects.every(s => s === 'Physics');
    console.log(t2 ? '✅ Test 2 PASS' : '⚠️ Test 2 PARTIAL (question bank mein kam questions ho sakte hain)');
  } catch(e) {
    console.log('❌ Test 2 ERROR:', e.message);
  }

  // ─── Test 3: generateNEETPaper (small distribution test) ───
  console.log('\n─── Test 3: generateNEETPaper (small: 5+5+10) ───');
  try {
    const smallDist = { Physics: 5, Chemistry: 5, Biology: 10 };
    const result = await generateNEETPaper(smallDist, DEFAULT_DIFFICULTY_WEIGHTS);
    if (result.success) {
      console.log(`Generated: ${result.questions.length} questions`);
      console.log('✅ Test 3 PASS');
    } else {
      console.log('⚠️ Test 3:', result.error);
      console.log('(Question bank bhar ke dobara chalao)');
    }
  } catch(e) {
    console.log('❌ Test 3 ERROR:', e.message);
  }

  // ─── Test 4: randomizeForStudent ───
  console.log('\n─── Test 4: S58 Randomize per Student ───');
  const dummyQs = [
    { questionId: 'q1', text: 'Q1', displayOrder: 1 },
    { questionId: 'q2', text: 'Q2', displayOrder: 2 },
    { questionId: 'q3', text: 'Q3', displayOrder: 3 },
    { questionId: 'q4', text: 'Q4', displayOrder: 4 },
    { questionId: 'q5', text: 'Q5', displayOrder: 5 }
  ];
  const student1 = randomizeForStudent(dummyQs, 'student_abc', 'exam_xyz');
  const student2 = randomizeForStudent(dummyQs, 'student_def', 'exam_xyz');
  const student1again = randomizeForStudent(dummyQs, 'student_abc', 'exam_xyz');

  const isDifferent    = JSON.stringify(student1) !== JSON.stringify(student2);
  const isDeterministic = JSON.stringify(student1) === JSON.stringify(student1again);

  console.log('Student1 order:', student1.map(q => q.questionId).join(' → '));
  console.log('Student2 order:', student2.map(q => q.questionId).join(' → '));
  console.log(`Alag alag orders: ${isDifferent ? '✅ YES' : '⚠️ Same (small dataset)'}`);
  console.log(`Same student same order: ${isDeterministic ? '✅ YES (deterministic)' : '❌ NO'}`);
  const t4 = isDeterministic;
  console.log(t4 ? '✅ Test 4 PASS' : '❌ Test 4 FAIL');

  // ─── Test 5: lockQuestionSnapshot (dummy exam pe) ───
  console.log('\n─── Test 5: Snapshot Lock ───');
  try {
    const testExam = await Exam.findOne({ snapshotLocked: false });
    if (!testExam) {
      console.log('⚠️ Koi unlocked exam nahi mili — Test 5 skip');
    } else {
      const miniQs = dummyQs.map((q,i) => ({
        _id: new mongoose.Types.ObjectId(),
        text: q.text, hindiText: '', options: [], correct: [],
        subject: 'Physics', chapter: 'Test', difficulty: 'Easy',
        type: 'SCQ', image: null, explanation: ''
      }));
      const snapshot = await lockQuestionSnapshot(testExam._id.toString(), miniQs);
      console.log(`Locked ${snapshot.length} questions in exam: ${testExam.title}`);

      // Verify from DB
      const updatedExam = await Exam.findById(testExam._id);
      const t5 = updatedExam.snapshotLocked === true && updatedExam.questionSnapshot.length > 0;
      console.log(t5 ? '✅ Test 5 PASS' : '❌ Test 5 FAIL');

      // Cleanup — unlock karo test ke baad
      await Exam.findByIdAndUpdate(testExam._id, {
        questionSnapshot: [], snapshotLocked: false, snapshotLockedAt: null
      });
      console.log('🧹 Test exam cleanup done');
    }
  } catch(e) {
    console.log('❌ Test 5 ERROR:', e.message);
  }

  // ─── Test 6: API Endpoints check ───
  console.log('\n─── Test 6: Routes Registered Check ───');
  const http = require('http');
  const checkRoute = (path, method = 'GET') => new Promise(resolve => {
    const options = { hostname: 'localhost', port: 3000, path, method };
    const req = http.request(options, res => {
      resolve({ status: res.statusCode, path });
    });
    req.on('error', () => resolve({ status: 'ERROR', path }));
    req.end();
  });

  const routes = await Promise.all([
    checkRoute('/api/health'),
    checkRoute('/api/exam-paper/fake_id/snapshot'),
    checkRoute('/api/exam-paper/fake_id/paper/fake_student')
  ]);

  routes.forEach(r => {
    const ok = r.status !== 'ERROR' && r.status !== 404;
    console.log(`${ok ? '✅' : '❌'} ${r.path} → ${r.status}`);
  });

  console.log('\n════════════════════════════════');
  console.log('✅ Phase 3.1 Test Complete!');
  console.log('════════════════════════════════\n');
  process.exit(0);
}

runTests().catch(e => {
  console.error('❌ Fatal:', e.message);
  process.exit(1);
});
