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
  console.log('\n🔥 Phase 6.3 — Result Control & Reports APIs Test\n');

  const login = await req('POST', '/api/auth/login', { email: 'admin@proverank.com', password: 'ProveRank@SuperAdmin123' });
  adminToken = login.body.token;
  const loginPass = login.status === 200 && adminToken;
  console.log(`${loginPass ? '✅' : '❌'} Login → HTTP ${login.status}`);
  results.push({ step: 0, name: 'Login', pass: loginPass });
  if (!adminToken) { console.log('❌ Token nahi mila'); return; }

  const fakeId = '000000000000000000000001';

  // Step 1: Publish Results
  const s1 = await req('POST', `/api/admin/results/${fakeId}/publish`, {}, adminToken);
  log(1, 'Publish Results API', s1, [200, 404]);

  // Step 2: Delay Results
  const s2 = await req('POST', `/api/admin/results/${fakeId}/delay`, { delayUntil: '2025-12-31', reason: 'Review pending' }, adminToken);
  log(2, 'Delay Results API', s2, [200, 404]);

  // Step 3: Manual Score Override
  const s3 = await req('PATCH', `/api/admin/results/${fakeId}/score-override`, { newScore: 500, reason: 'Manual correction' }, adminToken);
  log(3, 'Manual Score Override API', s3, [200, 404]);

  // Step 4: Rank List
  const s4 = await req('GET', `/api/admin/results/${fakeId}/rank-list`, null, adminToken);
  log(4, 'Rank List Generation API', s4, 200);

  // Step 5: Leaderboard (public)
  const s5 = await req('GET', `/api/admin/results/${fakeId}/leaderboard`, null, null);
  log(5, 'Leaderboard API (S15)', s5, 200);

  // Step 6: Publish Percentile
  const s6 = await req('POST', `/api/admin/results/${fakeId}/publish-percentile`, {}, adminToken);
  log(6, 'Percentile Publish API (S60)', s6, [200, 404]);

  // Step 7: Topper Solution Control
  const s7 = await req('PATCH', `/api/admin/results/${fakeId}/topper-solution`, { publish: true, topperSolutionUrl: 'https://example.com/topper.pdf' }, adminToken);
  log(7, 'Topper Solution PDF Control (S61)', s7, [200, 404]);

  // Step 8: Performance Report PDF
  const s8 = await req('GET', `/api/admin/results/${fakeId}/performance-report`, null, adminToken);
  log(8, 'Student Performance Report PDF (S14)', s8, [200, 404]);

  // Step 9: Result Export
  const s9 = await req('GET', `/api/admin/results/${fakeId}/export`, null, adminToken);
  log(9, 'Result Export JSON/CSV (S68)', s9, 200);

  // Step 10: Student Export
  const s10 = await req('GET', '/api/admin/students/export', null, adminToken);
  log(10, 'Student Export CSV (S67)', s10, 200);

  // Step 11: Answer Key Challenges
  const s11 = await req('GET', '/api/admin/challenges', null, adminToken);
  log(11, 'Answer Key Challenge API (S69)', s11, 200);

  // Step 12: Re-Evaluation Requests
  const s12 = await req('GET', '/api/admin/re-evaluations', null, adminToken);
  log(12, 'Re-Evaluation Request API (S71)', s12, 200);

  // Step 13: Grievances
  const s13 = await req('GET', '/api/admin/grievances', null, adminToken);
  log(13, 'Grievance Management API (S92)', s13, 200);

  // Step 14: Transparency Report
  const s14 = await req('GET', `/api/admin/results/${fakeId}/transparency`, null, null);
  log(14, 'Exam Transparency Report (S70)', s14, 200);

  const passed = results.filter(r => r.pass).length;
  const total = results.length;
  console.log(`\n${'─'.repeat(50)}`);
  console.log(`📊 Result: ${passed}/${total} PASSED`);
  if (passed === total) console.log('🏆 Phase 6.3 COMPLETE! All steps PASS ✅');
  else {
    console.log('⚠️ Failed steps:');
    results.filter(r => !r.pass).forEach(r => console.log(`   ❌ Step ${r.step}: ${r.name}`));
  }
}
run();
