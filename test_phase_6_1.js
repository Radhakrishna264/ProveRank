const BASE = 'http://localhost:3000';
let token = '';
let passed = 0;
let failed = 0;

async function req(method, url, body, headers = {}) {
  const opts = {
    method,
    headers: { 'Content-Type': 'application/json', ...headers }
  };
  if (body) opts.body = JSON.stringify(body);
  const r = await fetch(BASE + url, opts);
  return r.json();
}

function check(step, condition, msg) {
  if (condition) {
    console.log(`✅ STEP ${step} PASS — ${msg}`);
    passed++;
  } else {
    console.log(`❌ STEP ${step} FAIL — ${msg}`);
    failed++;
  }
}

async function run() {
  console.log('\n🚀 Phase 6.1 — Admin Dashboard APIs Test\n');

  // Login
  const login = await req('POST', '/api/auth/login', {
    email: 'admin@proverank.com',
    password: 'ProveRank@SuperAdmin123'
  });
  token = login.token;
  check(0, !!token, 'Admin login token mila');
  const auth = { Authorization: `Bearer ${token}` };

  // STEP 1 — Total Users
  const s1 = await req('GET', '/api/admin/stats/users', null, auth);
  check(1, s1.success && typeof s1.total === 'number', `Total Users Count API — total: ${s1.total}`);

  // STEP 2 — Total Exams
  const s2 = await req('GET', '/api/admin/stats/exams', null, auth);
  check(2, s2.success && typeof s2.total === 'number', `Total Exams Count API — total: ${s2.total}`);

  // STEP 3 — Active Attempts Live
  const s3 = await req('GET', '/api/admin/stats/active-attempts', null, auth);
  check(3, s3.success && typeof s3.active === 'number', `Active Attempts Live — active: ${s3.active}, socketBroadcast: ${s3.socketBroadcast}`);

  // STEP 4 — Cheating Alerts Summary
  const s4 = await req('GET', '/api/admin/stats/cheating-alerts', null, auth);
  check(4, s4.success && typeof s4.total === 'number', `Cheating Alerts Summary — total: ${s4.total}, webcam: ${s4.webcamFlags}, audio: ${s4.audioFlags}`);

  // STEP 5 — S13 Exam Analytics Dashboard
  const s5 = await req('GET', '/api/admin/analytics/exam-dashboard', null, auth);
  check(5, s5.success && Array.isArray(s5.examStats), `S13 Exam Analytics Dashboard — exams analyzed: ${s5.examStats?.length}`);

  // STEP 6 — S53 Platform Analytics
  const s6 = await req('GET', '/api/admin/analytics/platform', null, auth);
  check(6, s6.success && s6.serverHealth, `S53 Platform Analytics — uptime: ${s6.serverHealth?.uptimeHours}h, memory: ${s6.serverHealth?.memoryUsed}MB`);

  // STEP 7 — S108 Heatmap
  const s7 = await req('GET', '/api/admin/analytics/heatmap?days=30', null, auth);
  check(7, s7.success && Array.isArray(s7.heatmap), `S108 Exam Attempt Heatmap — data points: ${s7.heatmap?.length}`);

  // STEP 8 — S110 Retention Analytics
  const s8 = await req('GET', '/api/admin/analytics/retention', null, auth);
  check(8, s8.success && typeof s8.totalStudents === 'number', `S110 Student Retention — total: ${s8.totalStudents}, active7d: ${s8.activeLastWeek}, retention: ${s8.retentionRate7d}%`);

  // STEP 9 — N9 Series Analytics
  const s9 = await req('GET', '/api/admin/analytics/series', null, auth);
  check(9, s9.success && Array.isArray(s9.seriesList), `N9 Exam Series Analytics — series found: ${s9.seriesList?.length}`);

  // STEP 10 — M9 Question Bank Stats
  const s10 = await req('GET', '/api/admin/analytics/question-bank', null, auth);
  check(10, s10.success && typeof s10.totalQuestions === 'number', `M9 Question Bank Stats — total: ${s10.totalQuestions}`);

  // STEP 11 — N19 Institute Report Card PDF
  const pdfRes = await fetch(BASE + '/api/admin/reports/institute-report-card', {
    headers: { Authorization: `Bearer ${token}` }
  });
  check(11, pdfRes.headers.get('content-type')?.includes('pdf'), `N19 Institute Report Card PDF — content-type: ${pdfRes.headers.get('content-type')}`);

  console.log(`\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
  console.log(`✅ PASSED: ${passed} | ❌ FAILED: ${failed}`);
  if (failed === 0) console.log('🏆 PHASE 6.1 — ALL 11 STEPS PASS!');
  else console.log('⚠️  Kuch steps fail hue — upar dekho');
}

run().catch(e => console.error('❌ Script error:', e.message));
