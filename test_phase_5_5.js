const http = require('http');
const mongoose = require('mongoose');
const MONGO_URI = process.env.MONGO_URI;

function req(method, path, body, token) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = 'Bearer ' + token;
    if (data) headers['Content-Length'] = Buffer.byteLength(data);
    const r = http.request({ hostname: 'localhost', port: 3000, path, method, headers }, (res) => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => { try { resolve({ status: res.statusCode, body: JSON.parse(d) }); } catch { resolve({ status: res.statusCode, body: d }); } });
    });
    r.on('error', reject);
    if (data) r.write(data);
    r.end();
  });
}

function pass(n, msg, d) { console.log('✅ PASS Step ' + n + ' — ' + msg); if (d) console.log('   →', JSON.stringify(d).substring(0, 130)); }
function fail(n, msg, d) { console.log('❌ FAIL Step ' + n + ' — ' + msg); if (d) console.log('   →', JSON.stringify(d).substring(0, 200)); }

async function run() {
  console.log('\n══════════════════════════════════════════');
  console.log('  PHASE 5.5 TEST — Screen & Session Monitor');
  console.log('══════════════════════════════════════════\n');

  const sLogin = await req('POST', '/api/auth/login', { email: 'student@proverank.com', password: 'ProveRank@123' });
  if (!sLogin.body.token) { console.log('❌ Login failed'); return; }
  const sToken = sLogin.body.token;
  const sId = JSON.parse(Buffer.from(sToken.split('.')[1], 'base64').toString()).id;
  console.log('🔐 Student logged in');

  const aLogin = await req('POST', '/api/auth/login', { email: 'admin@proverank.com', password: 'ProveRank@SuperAdmin123' });
  const aToken = aLogin.body.token;
  console.log('🔐 Admin logged in\n');

  let attemptId, examId;
  try {
    await mongoose.connect(MONGO_URI);
    const Attempt = require('./src/models/Attempt');
    const att = await Attempt.findOne({ status: 'active' }).sort({ createdAt: -1 });
    if (att) { attemptId = att._id.toString(); examId = att.examId.toString(); }
    await mongoose.connection.close();
    console.log('📋 AttemptId:', attemptId, '\n');
  } catch (err) { console.log('DB error:', err.message); return; }

  if (!attemptId) { console.log('❌ No active attempt found'); return; }

  // STEP 1 — Screen Permission
  const s1 = await req('POST', '/api/session/screen-permission', { attemptId, examId, permissionStatus: 'granted' }, sToken);
  s1.status === 200
    ? pass(1, 'Screen capture permission logged', { status: 'granted' })
    : fail(1, 'Screen permission failed', s1.body);

  // STEP 2 — Session Metadata
  const s2 = await req('POST', '/api/session/metadata', {
    attemptId, examId,
    browser: 'Chrome 120', os: 'Android 13',
    screenResolution: '412x915', timezone: 'Asia/Kolkata', language: 'hi-IN'
  }, sToken);
  s2.status === 200 && s2.body.sessionMetadata
    ? pass(2, 'Session metadata recorded', { browser: s2.body.sessionMetadata.browser, os: s2.body.sessionMetadata.os, ip: s2.body.sessionMetadata.ipAddress })
    : fail(2, 'Metadata failed', s2.body);

  // STEP 3 — Suspicious Activity
  const s3 = await req('POST', '/api/session/suspicious', {
    attemptId, examId,
    activityType: 'devtools_open',
    flagReason: 'DevTools opened during exam'
  }, sToken);
  s3.status === 200 && s3.body.suspicious
    ? pass(3, 'Suspicious activity logged', { flagReason: s3.body.flagReason })
    : fail(3, 'Suspicious log failed', s3.body);

  // STEP 4 — IP Check (S20)
  const s4 = await req('POST', '/api/session/ip-check', { attemptId, examId }, sToken);
  s4.status === 200 || s4.status === 403
    ? pass(4, 'IP lock check working (S20)', { ipViolation: s4.body.ipViolation, currentIP: s4.body.currentIP })
    : fail(4, 'IP check failed', s4.body);

  // STEP 5 — Login Activity (S48)
  const s5 = await req('GET', '/api/session/login-activity/' + sId, null, aToken);
  s5.status === 200
    ? pass(5, 'Login activity fetched (S48)', { totalLogins: s5.body.totalLogins })
    : fail(5, 'Login activity failed', s5.body);

  // STEP 6 — Exam Health Monitor (S95)
  const s6 = await req('GET', '/api/session/exam-health/' + examId, null, aToken);
  s6.status === 200 && s6.body.liveStats
    ? pass(6, 'Exam health monitor working (S95)', {
        active: s6.body.liveStats.activeStudents,
        alertLevel: s6.body.alertLevel,
        memMB: s6.body.serverHealth.memoryUsageMB
      })
    : fail(6, 'Exam health failed', s6.body);

  // STEP 7 — Proctoring PDF (M15)
  const s7 = await new Promise((resolve) => {
    const options = {
      hostname: 'localhost', port: 3000,
      path: '/api/session/proctoring-pdf/' + attemptId,
      method: 'GET',
      headers: { 'Authorization': 'Bearer ' + aToken }
    };
    const r = http.request(options, (res) => {
      let size = 0;
      res.on('data', c => size += c.length);
      res.on('end', () => resolve({ status: res.statusCode, contentType: res.headers['content-type'], size }));
    });
    r.on('error', (err) => resolve({ status: 500, error: err.message }));
    r.end();
  });
  s7.status === 200 && s7.contentType && s7.contentType.includes('pdf')
    ? pass(7, 'Proctoring PDF generated (M15)', { sizeBytes: s7.size, contentType: s7.contentType })
    : fail(7, 'PDF generation failed', { status: s7.status, contentType: s7.contentType });

  // Admin Session Logs
  const admin = await req('GET', '/api/session/admin/logs/' + attemptId, null, aToken);
  if (admin.status === 200) console.log('\n📊 Session Logs: total=' + admin.body.totalLogs + ' suspicious=' + admin.body.suspicious);

  console.log('\n══════════════════════════════════════════');
  console.log('       PHASE 5.5 TEST COMPLETE ✅');
  console.log('══════════════════════════════════════════\n');
}

run().catch(err => { console.error('Test crashed:', err.message); process.exit(1); });
