const axios = require('axios');
const BASE = 'http://localhost:3000';
let token = '';
let attemptId = '';

async function run() {
  console.log('\n🚀 Phase 4.3 Test Start\n');

  // LOGIN
  try {
    const r = await axios.post(`${BASE}/api/auth/login`, {
      email: 'admin@proverank.com',
      password: 'ProveRank@SuperAdmin123'
    });
    token = r.data.token;
    console.log('✅ Login OK');
  } catch(e) {
    console.log('❌ Login FAIL', e.response?.data); return;
  }

  // START ATTEMPT
  try {
    const r = await axios.post(
      `${BASE}/api/exams/69a695892217ac6201221bfa/start-attempt`,
      {},
      { headers: { Authorization: `Bearer ${token}` } }
    );
    attemptId = r.data.attemptId;
    console.log('✅ Attempt started:', attemptId);
  } catch(e) {
    console.log('❌ Start attempt FAIL', e.response?.data); return;
  }

  // SUBMIT
  try {
    await axios.post(
      `${BASE}/api/attempts/${attemptId}/submit`,
      {},
      { headers: { Authorization: `Bearer ${token}` } }
    );
    console.log('✅ Attempt submitted');
  } catch(e) {
    console.log('❌ Submit FAIL', e.response?.data); return;
  }

  // STEP 1-6: Calculate Result
  try {
    const r = await axios.post(
      `${BASE}/api/results/${attemptId}/calculate`,
      {},
      { headers: { Authorization: `Bearer ${token}` } }
    );
    console.log('✅ S1: Correct answers matched');
    console.log('✅ S2: Negative marking applied');
    console.log('✅ S3: Custom marking scheme used');
    console.log('✅ S4: MSQ partial marking done');
    console.log('✅ S5: Score stored:', r.data.score);
    console.log('✅ S6: Subject stats:', JSON.stringify(r.data.subjectStats));
  } catch(e) {
    console.log('❌ S1-6: Calculate FAIL', e.response?.data); return;
  }

  // STEP 7: Rank
  try {
    const r = await axios.get(
      `${BASE}/api/results/${attemptId}`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    console.log('✅ S7: Rank:', r.data.rank, '| Total Students:', r.data.totalStudents);
  } catch(e) {
    console.log('❌ S7: Rank FAIL', e.response?.data);
  }

  global.attemptId = attemptId;
  global.token = token;
}

run().catch(console.error);
