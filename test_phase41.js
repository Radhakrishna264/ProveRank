const BASE = 'http://localhost:3000';

async function run() {
  console.log('\n🧪 Phase 4.1 Test — Attempt Start Logic\n');

  const loginRes = await fetch(`${BASE}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'student@test.com', password: 'ProveRank@123' })
  });
  const loginData = await loginRes.json();
  const token = loginData.token;
  if (!token) { console.log('❌ Login failed:', loginData); return; }
  console.log('✅ Student Login:', loginData.user?.name || loginData.user?.email || 'OK');

  const headers = { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` };

  const examRes = await fetch(`${BASE}/api/exams`, { headers });
  const examData = await examRes.json();
  const exam = examData.exams?.[0] || examData[0];
  if (!exam) { console.log('❌ Koi exam nahi mila'); return; }
  console.log('✅ Exam mila:', exam.title, '| ID:', exam._id);
  const examId = exam._id;

  const rankRes = await fetch(`${BASE}/api/attempts/rank-prediction/${examId}`, { headers });
  const rankData = await rankRes.json();
  console.log('📊 Step 1 Rank Prediction:', rankData.success ? '✅' : '❌', rankData.prediction?.message || rankData.message);

  const waitRes = await fetch(`${BASE}/api/attempts/waiting-room/${examId}`, { method: 'POST', headers });
  const waitData = await waitRes.json();
  console.log('🚪 Step 2 Waiting Room:', waitData.success ? '✅' : '⚠️ (OK if not scheduled)', waitData.message);

  const termsRes = await fetch(`${BASE}/api/attempts/accept-terms/${examId}`, {
    method: 'POST', headers, body: JSON.stringify({ agreed: true })
  });
  const termsData = await termsRes.json();
  console.log('📋 Step 3+4 Terms Accept:', termsData.success ? '✅' : '❌', termsData.message);

  const studentId = loginData.user?._id;
  const qrCode = `PROVERANK-${studentId}-${examId}`;
  const admitRes = await fetch(`${BASE}/api/attempts/verify-admit-card/${examId}`, {
    method: 'POST', headers, body: JSON.stringify({ qrCode })
  });
  const admitData = await admitRes.json();
  console.log('🪪 Step 10 Admit Card:', admitData.success ? '✅' : '❌', admitData.message);

  const startRes = await fetch(`${BASE}/api/attempts/start/${examId}`, {
    method: 'POST', headers,
    body: JSON.stringify({ predictedRank: rankData.prediction?.predictedRank, predictedScore: rankData.prediction?.predictedScore, predictionConfidence: rankData.prediction?.confidence })
  });
  const startData = await startRes.json();
  console.log('🚀 Step 5-9,11 Start Attempt:', startData.success ? '✅' : '❌', startData.message);
  if (startData.attempt) {
    console.log('   IP recorded:', startData.attempt.ipAddress ? '✅' : '❌');
    console.log('   Timestamp:', startData.attempt.startedAt ? '✅' : '❌');
    console.log('   Attempt #:', startData.attempt.attemptNumber);
  }

  const statusRes = await fetch(`${BASE}/api/attempts/status/${examId}`, { headers });
  const statusData = await statusRes.json();
  console.log('📍 Attempt Status:', statusData.status || 'N/A', statusData.hasAttempt ? '✅' : '❌');

  if (startData.attempt?._id) {
    const fsRes = await fetch(`${BASE}/api/attempts/fullscreen-warning/${startData.attempt._id}`, { method: 'POST', headers });
    const fsData = await fsRes.json();
    console.log('🖥️ Step 11 Fullscreen Warning:', fsData.success ? '✅' : '❌', fsData.message);
  }

  console.log('\n✅ Phase 4.1 Test Complete!\n');
}

run().catch(console.error);
