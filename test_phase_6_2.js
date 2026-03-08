const http = require('http');

const BASE = 'localhost';
const PORT = 3000;
let adminToken = '';
let results = [];

function req(method, path, body, token) {
  return new Promise((resolve) => {
    const data = body ? JSON.stringify(body) : null;
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;
    const options = { hostname: BASE, port: PORT, path, method, headers };
    const r = http.request(options, (res) => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(d) }); }
        catch { resolve({ status: res.statusCode, body: d }); }
      });
    });
    r.on('error', (e) => resolve({ status: 0, body: { error: e.message } }));
    if (data) r.write(data);
    r.end();
  });
}

function log(step, name, res, expectStatus) {
  const pass = res.status === expectStatus;
  const icon = pass ? '✅' : '❌';
  console.log(`${icon} Step ${step}: ${name} → HTTP ${res.status}`);
  if (!pass) console.log(`   Expected: ${expectStatus} | Got: ${res.status} | Body: ${JSON.stringify(res.body).substring(0,150)}`);
  results.push({ step, name, pass });
}

async function run() {
  console.log('\n🔥 Phase 6.2 — Monitoring & Control Panel APIs Test\n');

  // Login
  const login = await req('POST', '/api/auth/login', {
    email: 'admin@proverank.com',
    password: 'ProveRank@SuperAdmin123'
  });
  adminToken = login.body.token;
  const loginPass = login.status === 200 && adminToken;
  console.log(`${loginPass ? '✅' : '❌'} Login → HTTP ${login.status}`);
  results.push({ step: 0, name: 'SuperAdmin Login', pass: loginPass });

  if (!adminToken) { console.log('❌ Token nahi mila — test stop'); return; }

  // Step 1: Student Attempts API
  const s1 = await req('GET', '/api/admin/attempts', null, adminToken);
  log(1, 'Student Attempts API (with filters)', s1, 200);

  // Step 2: Cheating Logs API
  const s2 = await req('GET', '/api/admin/cheat-logs', null, adminToken);
  log(2, 'Cheating Logs API', s2, 200);

  // Step 3: Webcam Snapshots API
  const s3 = await req('GET', '/api/admin/snapshots', null, adminToken);
  log(3, 'Webcam Snapshots API', s3, 200);

  // Step 4: Audio Flags API (S57)
  const s4 = await req('GET', '/api/admin/audio-flags', null, adminToken);
  log(4, 'Audio Flags Review API (S57)', s4, 200);

  // Step 5: Live Exam Control Panel - GET
  const s5 = await req('GET', '/api/admin/exam-control/000000000000000000000001', null, adminToken);
  log(5, 'Live Exam Control Panel GET (S83)', s5, 200);

  // Step 6: Per-Student Time Extension (M7)
  const s6 = await req('POST', '/api/admin/time-extension', {
    examId: '000000000000000000000001',
    studentId: '000000000000000000000002',
    extraMinutes: 10,
    reason: 'Technical issue'
  }, adminToken);
  // 404 = no active attempt (acceptable), 200 = success, 400 = missing fields
  const s6pass = [200, 404].includes(s6.status);
  console.log(`${s6pass ? '✅' : '❌'} Step 6: Per-Student Time Extension (M7) → HTTP ${s6.status}`);
  results.push({ step: 6, name: 'Time Extension M7', pass: s6pass });

  // Step 7: Admin Notifications GET
  const s7 = await req('GET', '/api/admin/notifications', null, adminToken);
  log(7, 'Admin Notification Center (S86)', s7, 200);

  // Step 7b: Mark all read
  const s7b = await req('PATCH', '/api/admin/notifications/mark-all-read', {}, adminToken);
  log('7b', 'Notifications Mark All Read', s7b, 200);

  // Step 8: SuperAdmin Permission Control (S72)
  const s8 = await req('GET', '/api/admin/permissions', null, adminToken);
  log(8, 'SuperAdmin Permission Control (S72)', s8, 200);

  // Step 9: Admin Activity Logs (S38)
  const s9 = await req('GET', '/api/admin/admin-logs', null, adminToken);
  log(9, 'Admin Activity Logs (S38)', s9, 200);

  // Step 10: Audit Trail (S93)
  const s10 = await req('GET', '/api/admin/audit-trail', null, adminToken);
  log(10, 'Platform Audit Trail (S93)', s10, 200);

  // Step 11: Login Activity Monitor (S48)
  const s11 = await req('GET', '/api/admin/login-activity', null, adminToken);
  log(11, 'Login Activity Monitor (S48)', s11, 200);

  // Summary
  const passed = results.filter(r => r.pass).length;
  const total = results.length;
  console.log(`\n${'─'.repeat(50)}`);
  console.log(`📊 Result: ${passed}/${total} PASSED`);
  if (passed === total) {
    console.log('🏆 Phase 6.2 COMPLETE! All steps PASS ✅');
  } else {
    console.log('⚠️ Kuch steps fail hue — upar dekho');
    results.filter(r => !r.pass).forEach(r => console.log(`   ❌ Step ${r.step}: ${r.name}`));
  }
}

run();
