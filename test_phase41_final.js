const BASE = 'http://localhost:3000';
const EXAM_ID = '69a3f3bce9d2dba98956468c';
const STUDENT_ID = '69a68c98043a3e19b0efeb33';

async function run() {
  console.log('\n🧪 Phase 4.1 Test — Attempt Start Logic\n');

  const loginData = await (await fetch(BASE + '/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'phase41test@test.com', password: 'ProveRank@123' })
  })).json();

  const token = loginData.token;
  if (!token) { console.log('❌ Login failed:', JSON.stringify(loginData)); return; }
  console.log('✅ Login OK');

  const headers = { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token };

  const r1 = await (await fetch(BASE + '/api/attempts/rank-prediction/' + EXAM_ID, { headers })).json();
  console.log('📊 Step 1 Rank Prediction:', r1.success ? '✅' : '❌', r1.prediction?.message || r1.message);

  const r2 = await (await fetch(BASE + '/api/attempts/waiting-room/' + EXAM_ID, { method: 'POST', headers })).json();
  console.log('🚪 Step 2 Waiting Room:', r2.success ? '✅' : '⚠️ (OK)', r2.message);

  const r3 = await (await fetch(BASE + '/api/attempts/accept-terms/' + EXAM_ID, {
    method: 'POST', headers,
    body: JSON.stringify({ agreed: true })
  })).json();
  console.log('📋 Step 3+4 Terms:', r3.success ? '✅' : '❌', r3.message);

  const r4 = await (await fetch(BASE + '/api/attempts/verify-admit-card/' + EXAM_ID, {
    method: 'POST', headers,
    body: JSON.stringify({ qrCode: 'PROVERANK-' + STUDENT_ID + '-' + EXAM_ID })
  })).json();
  console.log('🪪 Step 10 Admit Card:', r4.success ? '✅' : '❌', r4.message);

  const r5 = await (await fetch(BASE + '/api/attempts/start/' + EXAM_ID, {
    method: 'POST', headers,
    body: JSON.stringify({ predictedRank: 5000, predictedScore: 500, predictionConfidence: 'medium' })
  })).json();
  console.log('🚀 Step 5-9,11 Start:', r5.success ? '✅' : '❌', r5.message);
  if (r5.attempt) {
    console.log('   IP recorded:', r5.attempt.ipAddress ? '✅' : '❌', r5.attempt.ipAddress);
    console.log('   Timestamp:', r5.attempt.startedAt ? '✅' : '❌');
    console.log('   Attempt #:', r5.attempt.attemptNumber);
  }

  const r6 = await (await fetch(BASE + '/api/attempts/status/' + EXAM_ID, { headers })).json();
  console.log('📍 Status:', r6.status || 'N/A', r6.hasAttempt ? '✅' : '❌');

  if (r5.attempt && r5.attempt._id) {
    const r7 = await (await fetch(BASE + '/api/attempts/fullscreen-warning/' + r5.attempt._id, {
      method: 'POST', headers
    })).json();
    console.log('🖥️  Step 11 Fullscreen:', r7.success ? '✅' : '❌', r7.message);
  }

  console.log('\n✅ Phase 4.1 Test Complete!\n');
}

run().catch(console.error);
