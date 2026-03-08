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

function pass(n, msg, d) { console.log('✅ PASS Step ' + n + ' — ' + msg); if (d) console.log('   →', JSON.stringify(d).substring(0, 120)); }
function fail(n, msg, d) { console.log('❌ FAIL Step ' + n + ' — ' + msg); if (d) console.log('   →', JSON.stringify(d).substring(0, 200)); }

async function run() {
  console.log('\n══════════════════════════════════════');
  console.log('  PHASE 5.3 TEST — Audio Monitoring');
  console.log('══════════════════════════════════════\n');

  const sLogin = await req('POST', '/api/auth/login', { email: 'student@proverank.com', password: 'ProveRank@123' });
  if (!sLogin.body.token) { console.log('❌ Login failed'); return; }
  const sToken = sLogin.body.token;
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

  // STEP 1a — Mic Permission Granted
  const s1a = await req('POST', '/api/audio/permission', { attemptId, examId, permissionStatus: 'granted' }, sToken);
  s1a.status === 200 ? pass('1a', 'Mic permission granted — logged', { permissionStatus: 'granted' }) : fail('1a', 'Permission API failed', s1a.body);

  // STEP 1b — Mic Permission Denied
  const s1b = await req('POST', '/api/audio/permission', { attemptId, examId, permissionStatus: 'denied' }, sToken);
  s1b.status === 200 ? pass('1b', 'Mic permission denied — logged (optional)', { note: s1b.body.note }) : fail('1b', 'Permission denied failed', s1b.body);

  // STEP 2a — Noise Detected
  const s2a = await req('POST', '/api/audio/noise-flag', { attemptId, examId, noiseType: 'noise_detected', noiseLevel: 85, metadata: { duration: 2.3 } }, sToken);
  s2a.status === 200 && s2a.body.audioFlag ? pass(2, 'Noise detected — flagged', { noiseLevel: s2a.body.noiseLevel, audioFlag: s2a.body.audioFlag }) : fail(2, 'Noise flag failed', s2a.body);

  // STEP 2b — Whisper Detected
  const s2b = await req('POST', '/api/audio/noise-flag', { attemptId, examId, noiseType: 'whisper_detected', noiseLevel: 40 }, sToken);
  s2b.status === 200 && s2b.body.audioFlag ? pass('2b', 'Whisper detected — flagged', { flagReason: s2b.body.flagReason }) : fail('2b', 'Whisper flag failed', s2b.body);

  // STEP 3 — Save Audio Flag
  const s3 = await req('POST', '/api/audio/flag', { attemptId, examId, flagReason: 'Multiple voices detected', noiseLevel: 92 }, sToken);
  s3.status === 200 && s3.body.audioFlag ? pass(3, 'Audio flag saved to backend', { flagId: s3.body.flagId, flagReason: s3.body.flagReason }) : fail(3, 'Audio flag save failed', s3.body);

  // STEP 4 — Admin Toggle ON (S57)
  const s4on = await req('POST', '/api/audio/admin/toggle/' + examId, { enabled: true }, aToken);
  s4on.status === 200 && s4on.body.audioMonitoringEnabled === true ? pass('4a', 'Audio monitoring toggled ON (S57)', { enabled: s4on.body.audioMonitoringEnabled }) : fail('4a', 'Toggle ON failed', s4on.body);

  // STEP 4 — Admin Toggle OFF
  const s4off = await req('POST', '/api/audio/admin/toggle/' + examId, { enabled: false }, aToken);
  s4off.status === 200 && s4off.body.audioMonitoringEnabled === false ? pass('4b', 'Audio monitoring toggled OFF (S57)', { enabled: s4off.body.audioMonitoringEnabled }) : fail('4b', 'Toggle OFF failed', s4off.body);

  // Admin Status Check
  const status = await req('GET', '/api/audio/admin/status/' + examId, null, aToken);
  if (status.status === 200) console.log('\n📊 Audio Status:', status.body.audioMonitoringEnabled ? 'ON' : 'OFF', '| Exam:', status.body.examTitle);

  // Admin Logs
  const logs = await req('GET', '/api/audio/admin/logs/' + attemptId, null, aToken);
  if (logs.status === 200) console.log('📊 Audio Logs: total=' + logs.body.totalLogs + ' flagged=' + logs.body.totalFlagged);

  console.log('\n══════════════════════════════════════');
  console.log('     PHASE 5.3 TEST COMPLETE ✅');
  console.log('══════════════════════════════════════\n');
}

run().catch(err => { console.error('Test crashed:', err.message); process.exit(1); });
