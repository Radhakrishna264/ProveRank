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
  console.log('  PHASE 5.2 TEST — Webcam Enforcement');
  console.log('══════════════════════════════════════\n');

  const sLogin = await req('POST', '/api/auth/login', { email: 'student@proverank.com', password: 'ProveRank@123' });
  if (!sLogin.body.token) { console.log('❌ Student login failed'); return; }
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

  // STEP 1 — Camera Permission Granted
  const s1 = await req('POST', '/api/webcam/permission', { attemptId, examId, permissionStatus: 'granted', metadata: { browser: 'Chrome' } }, sToken);
  s1.status === 200 ? pass(1, 'Camera permission logged (granted)', { permissionStatus: 'granted', cheatingFlag: s1.body.cheatingFlag }) : fail(1, 'Permission API failed', s1.body);

  // STEP 1b — Camera Permission Denied test
  const s1b = await req('POST', '/api/webcam/permission', { attemptId, examId, permissionStatus: 'denied' }, sToken);
  s1b.status === 200 && s1b.body.cheatingFlag === true ? pass('1b', 'Camera denied = cheatingFlag:true', { cheatingFlag: s1b.body.cheatingFlag }) : fail('1b', 'Denied flag not set', s1b.body);

  // STEP 2 — Block Exam Check
  const s2 = await req('POST', '/api/webcam/block-exam', { attemptId, examId }, sToken);
  s2.status === 200 || s2.status === 403
    ? pass(2, 'Block exam API working', { examBlocked: s2.body.examBlocked, status: s2.status })
    : fail(2, 'Block exam failed', s2.body);

  // STEP 3 & 4 — Snapshot Upload
  const fakeSnapshot = 'data:image/jpeg;base64,' + Buffer.from('fake_snapshot_data_for_test').toString('base64');
  const s3 = await req('POST', '/api/webcam/snapshot', { attemptId, examId, snapshotBase64: fakeSnapshot, metadata: { snapshotNumber: 1 } }, sToken);
  s3.status === 200 && s3.body.snapshotId ? pass(3, 'Snapshot uploaded + stored', { snapshotId: s3.body.snapshotId, size: s3.body.sizeBytes }) : fail(3, 'Snapshot upload failed', s3.body);

  // STEP 5 — Cheating Flag with Snapshot
  const s5 = await req('POST', '/api/webcam/flag-snapshot', { attemptId, examId, flagReason: 'Multiple faces detected', snapshotBase64: fakeSnapshot }, sToken);
  s5.status === 200 && s5.body.cheatingFlag ? pass(5, 'Cheating flag saved with snapshot', { flagReason: s5.body.flagReason }) : fail(5, 'Flag snapshot failed', s5.body);

  // STEP 6 — Virtual Background (S74)
  const s6 = await req('POST', '/api/webcam/virtual-bg-flag', { attemptId, examId, confidence: 'high', metadata: { detectionMethod: 'pixel_analysis' } }, sToken);
  s6.status === 200 && s6.body.cheatingFlag ? pass(6, 'Virtual background flagged (S74)', { action: s6.body.action, confidence: s6.body.confidence }) : fail(6, 'Virtual BG flag failed', s6.body);

  // ADMIN — Snapshots
  const admin1 = await req('GET', '/api/webcam/admin/snapshots/' + attemptId, null, aToken);
  admin1.status === 200 ? console.log('\n📊 Admin Snapshots: total=' + admin1.body.totalLogs + ' flagged=' + admin1.body.totalFlagged) : console.log('Admin snapshots error:', admin1.body);

  // ADMIN — All Flagged
  const admin2 = await req('GET', '/api/webcam/admin/flagged', null, aToken);
  admin2.status === 200 ? console.log('📊 Admin Flagged Events:', admin2.body.totalFlagged) : console.log('Admin flagged error:', admin2.body);

  console.log('\n══════════════════════════════════════');
  console.log('     PHASE 5.2 TEST COMPLETE ✅');
  console.log('══════════════════════════════════════\n');
}

run().catch(err => { console.error('Test crashed:', err.message); process.exit(1); });
