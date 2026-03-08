const http = require('http');
const BASE = 'localhost', PORT = 3000;
let adminToken = '', results = [];

function req(method, path, body, token) {
  return new Promise((resolve) => {
    const data = body ? JSON.stringify(body) : null;
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;
    const r = http.request({ hostname: BASE, port: PORT, path, method, headers }, (res) => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(d) }); }
        catch { resolve({ status: res.statusCode, body: d }); }
      });
    });
    r.on('error', e => resolve({ status: 0, body: { error: e.message } }));
    if (data) r.write(data);
    r.end();
  });
}

function log(step, name, res, expectStatus) {
  const pass = Array.isArray(expectStatus) ? expectStatus.includes(res.status) : res.status === expectStatus;
  console.log(`${pass ? '✅' : '❌'} Step ${step}: ${name} → HTTP ${res.status}`);
  if (!pass) console.log(`   Expected: ${JSON.stringify(expectStatus)} | Body: ${JSON.stringify(res.body).substring(0,120)}`);
  results.push({ step, name, pass });
}

async function run() {
  console.log('\n🔥 Phase 6.4 — Question & Exam Management APIs Test\n');

  const login = await req('POST', '/api/auth/login', { email: 'admin@proverank.com', password: 'ProveRank@SuperAdmin123' });
  adminToken = login.body.token;
  const loginPass = login.status === 200 && adminToken;
  console.log(`${loginPass ? '✅' : '❌'} Login → HTTP ${login.status}`);
  results.push({ step: 0, name: 'Login', pass: loginPass });
  if (!adminToken) { console.log('❌ Token nahi mila'); return; }

  const fakeId = '000000000000000000000001';

  // Step 1: Question Bank CRUD + Search
  const s1a = await req('GET', '/api/admin/questions', null, adminToken);
  log('1a', 'Question Bank List + Filter', s1a, 200);

  const s1b = await req('POST', '/api/admin/questions', {
    text: 'Test Question for Phase 6.4',
    options: ['Option A', 'Option B', 'Option C', 'Option D'],
    correctAnswer: 0,
    subject: 'Physics',
    chapter: 'Motion',
    difficulty: 'easy'
  }, adminToken);
  log('1b', 'Question Create', s1b, [200, 201]);

  let questionId = s1b.body.question?._id || fakeId;

  const s1c = await req('PUT', `/api/admin/questions/${questionId}`, {
    difficulty: 'medium', chapter: 'Motion Updated'
  }, adminToken);
  log('1c', 'Question Update', s1c, [200, 404]);

  // Step 2: Question Preview (S17)
  const s2 = await req('GET', `/api/admin/questions/${questionId}/preview`, null, adminToken);
  log(2, 'Question Preview Before Publish (S17)', s2, [200, 404]);

  // Step 3: Version History (S87)
  const s3 = await req('GET', `/api/admin/questions/${questionId}/versions`, null, adminToken);
  log(3, 'Question Version History (S87)', s3, 200);

  // Step 4: Duplicate Detector (S18)
  const s4 = await req('POST', '/api/admin/questions/check-duplicate', {
    questionText: 'Test Question for Phase 6.4'
  }, adminToken);
  log(4, 'Duplicate Question Detector (S18)', s4, 200);

  // Step 5: Question Error Reports (S84)
  const s5 = await req('GET', '/api/admin/question-errors', null, adminToken);
  log(5, 'Question Error Reporting (S84)', s5, 200);

  // Step 6: Smart Paper Generator (S101)
  const s6 = await req('POST', '/api/admin/generate-paper', {
    totalQuestions: 180,
    physics: 45, chemistry: 45, biology: 90,
    difficulty: 'mixed',
    examTitle: 'Auto NEET Mock Test'
  }, adminToken);
  log(6, 'Smart Question Paper Generator (S101)', s6, 200);

  // Step 7: PYQ Bank (S104)
  const s7 = await req('GET', '/api/admin/pyq', null, adminToken);
  log(7, 'PYQ Bank Management (S104)', s7, 200);

  // Step 8: Mini Test Generator (S103)
  const s8 = await req('POST', '/api/admin/mini-test/generate', {
    subject: 'Physics', chapter: 'Motion', count: 10
  }, adminToken);
  log(8, 'Chapter Mini Test Generator (S103)', s8, 200);

  // Step 9: Doubt System (S63)
  const s9 = await req('GET', '/api/admin/doubts', null, adminToken);
  log(9, 'Doubt/Query System (S63)', s9, 200);

  // Step 10: Bulk Exam Creator (N8)
  const s10 = await req('POST', '/api/admin/exams/bulk-create', {
    exams: [
      { title: 'Bulk Exam 1', totalQuestions: 180, duration: 200 },
      { title: 'Bulk Exam 2', totalQuestions: 180, duration: 200 }
    ]
  }, adminToken);
  log(10, 'Bulk Exam Creator (N8)', s10, 200);

  // Step 11: Batch Comparison (M8)
  const s11 = await req('GET', '/api/admin/batches/compare?batch1=NEET2024&batch2=NEET2025', null, adminToken);
  log(11, 'Batch vs Batch Comparison (M8)', s11, 200);

  // Step 12: Batch Transfer (M3)
  const s12 = await req('POST', '/api/admin/batches/transfer', {
    fromBatch: 'NEET2024', toBatch: 'NEET2025-Upgraded'
  }, adminToken);
  log(12, 'Batch Transfer System (M3)', s12, 200);

  // Cleanup: delete test question
  if (questionId !== fakeId) {
    await req('DELETE', `/api/admin/questions/${questionId}`, null, adminToken);
    console.log('🧹 Test question cleaned up');
  }

  const passed = results.filter(r => r.pass).length;
  const total = results.length;
  console.log(`\n${'─'.repeat(50)}`);
  console.log(`📊 Result: ${passed}/${total} PASSED`);
  if (passed === total) console.log('🏆 Phase 6.4 COMPLETE! All steps PASS ✅');
  else {
    console.log('⚠️ Failed steps:');
    results.filter(r => !r.pass).forEach(r => console.log(`   ❌ Step ${r.step}: ${r.name}`));
  }
}
run();
