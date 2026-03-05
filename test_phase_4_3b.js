const axios = require('axios');
const BASE = 'http://localhost:3000';

async function run() {
  console.log('\n🚀 Phase 4.3 Test — Steps 8 to 13\n');

  // LOGIN
  let token = '';
  let attemptId = '';

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

    // CREATE FRESH ATTEMPT + SUBMIT
  try {
    const examRes = await axios.get(
      `${BASE}/api/exams`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    const examId = examRes.data.exams?.[0]?._id || examRes.data[0]?._id;
    if (!examId) { console.log('❌ No exam found'); return; }

    const startRes = await axios.post(
      `${BASE}/api/exams/${examId}/start-attempt`,
      {},
      { headers: { Authorization: `Bearer ${token}` } }
    );
    attemptId = startRes.data.attemptId || startRes.data.attempt?._id || startRes.data._id;
    if (!attemptId) { console.log('❌ Start attempt FAIL', startRes.data); return; }
    console.log('✅ Attempt created:', attemptId);

    await axios.post(
      `${BASE}/api/attempts/${attemptId}/submit`,
      {},
      { headers: { Authorization: `Bearer ${token}` } }
    );
    console.log('✅ Attempt submitted');
  } catch(e) {
    console.log('❌ Setup FAIL', e.response?.data); return;
  }

  // STEP 8: Percentile
  try {
    const r = await axios.get(
      `${BASE}/api/results/${attemptId}`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    console.log('✅ S8: Percentile:', r.data.percentile, '%');
  } catch(e) {
    console.log('❌ S8: Percentile FAIL', e.response?.data);
  }

  // STEP 9: Socket Live Rank (calculate trigger karta hai broadcast)
  try {
    const r = await axios.post(
      `${BASE}/api/results/${attemptId}/calculate`,
      {},
      { headers: { Authorization: `Bearer ${token}` } }
    );
    console.log('✅ S9: Live Rank broadcast triggered | Rank:', r.data.rank);
  } catch(e) {
    console.log('❌ S9: Live Rank FAIL', e.response?.data);
  }

  // STEP 10: Difficulty Auto-Adjuster
  try {
    const r = await axios.post(
      `${BASE}/api/results/${attemptId}/calculate`,
      {},
      { headers: { Authorization: `Bearer ${token}` } }
    );
    const flag = r.data.difficultyFlag;
    console.log('✅ S10: Difficulty flag checked:', flag?.flagged ? '⚠️ Flagged' : '✅ Normal');
  } catch(e) {
    console.log('❌ S10: Difficulty FAIL', e.response?.data);
  }

  // STEP 11: OMR Sheet
  try {
    const r = await axios.get(
      `${BASE}/api/results/${attemptId}/ormsheet`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    console.log('✅ S11: OMR Sheet generated | Rows:', r.data.ormSheet?.length);
  } catch(e) {
    console.log('❌ S11: OMR Sheet FAIL', e.response?.data);
  }

  // STEP 12: Share Card
  try {
    const r = await axios.get(
      `${BASE}/api/results/${attemptId}/share-card`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    console.log('✅ S12: Share Card generated | Student:', r.data.shareCard?.studentName);
  } catch(e) {
    console.log('❌ S12: Share Card FAIL', e.response?.data);
  }

  // STEP 13: Receipt PDF
  try {
    const r = await axios.get(
      `${BASE}/api/results/${attemptId}/receipt`,
      {
        headers: { Authorization: `Bearer ${token}` },
        responseType: 'arraybuffer'
      }
    );
    const size = r.data.byteLength;
    console.log('✅ S13: Receipt PDF generated | Size:', size, 'bytes');
  } catch(e) {
    console.log('❌ S13: Receipt PDF FAIL', e.response?.data);
  }

  console.log('\n🎯 Phase 4.3 Steps 8-13 Test Complete!\n');
}

run().catch(console.error);
