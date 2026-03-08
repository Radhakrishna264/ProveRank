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
  console.log('\n══════════════════════════════════════');
  console.log('  PHASE 5.4 TEST — Face Detection AI');
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

  // STEP 1+2 — Model Status
  const s1 = await req('GET', '/api/face/model-status', null, sToken);
  s1.status === 200 && s1.body.modelReady
    ? pass('1+2', 'TensorFlow model status OK', { tfAvailable: s1.body.tensorflowAvailable, modelReady: s1.body.modelReady })
    : fail('1+2', 'Model status failed', s1.body);

  // STEP 3 — Single Face OK
  const s3 = await req('POST', '/api/face/single-face', { attemptId, examId, confidence: 0.97 }, sToken);
  s3.status === 200 && s3.body.warningIssued === false
    ? pass(3, 'Single face verified — OK', { faceCount: s3.body.faceCount })
    : fail(3, 'Single face failed', s3.body);

  // STEP 4 — Multiple Faces
  const s4 = await req('POST', '/api/face/multiple-faces', { attemptId, examId, faceCount: 2 }, sToken);
  s4.status === 200 && s4.body.warningIssued === true
    ? pass(4, 'Multiple faces detected — alert issued', { faceCount: s4.body.faceCount, warnings: s4.body.totalFaceWarnings })
    : fail(4, 'Multiple faces failed', s4.body);

  // STEP 5 — No Face
  const s5 = await req('POST', '/api/face/no-face', { attemptId, examId, duration: 5 }, sToken);
  s5.status === 200 && s5.body.warningIssued === true
    ? pass(5, 'No face detected — alert issued', { warnings: s5.body.totalFaceWarnings })
    : fail(5, 'No face failed', s5.body);

  // STEP 6 — Warning Counter
  const s6 = await req('GET', '/api/face/warning-count/' + attemptId, null, sToken);
  s6.status === 200 && s6.body.totalFaceWarnings !== undefined
    ? pass(6, 'Face warning counter working', { total: s6.body.totalFaceWarnings, riskLevel: s6.body.riskLevel, breakdown: s6.body.breakdown })
    : fail(6, 'Warning counter failed', s6.body);

  // STEP 7 — Eye Tracking (S-ET)
  const s7 = await req('POST', '/api/face/eye-tracking', { attemptId, examId, gazeDirection: 'down', duration: 4 }, sToken);
  s7.status === 200 && s7.body.isSuspicious === true
    ? pass(7, 'Eye tracking flagged (S-ET)', { gaze: s7.body.gazeDirection, warning: s7.body.warningIssued })
    : fail(7, 'Eye tracking failed', s7.body);

  // STEP 7b — Eye OK (looking at screen)
  const s7b = await req('POST', '/api/face/eye-tracking', { attemptId, examId, gazeDirection: 'center', duration: 1 }, sToken);
  s7b.status === 200 && s7b.body.isSuspicious === false
    ? pass('7b', 'Eye tracking center — no flag', { gaze: s7b.body.gazeDirection })
    : fail('7b', 'Eye center check failed', s7b.body);

  // STEP 8 — Head Pose (S73)
  const s8 = await req('POST', '/api/face/head-pose', { attemptId, examId, poseDirection: 'left', poseAngle: 45, duration: 3 }, sToken);
  s8.status === 200 && s8.body.isSuspicious === true
    ? pass(8, 'Head pose flagged (S73)', { direction: s8.body.poseDirection, angle: s8.body.poseAngle })
    : fail(8, 'Head pose failed', s8.body);

  // STEP 8b — Head OK (straight)
  const s8b = await req('POST', '/api/face/head-pose', { attemptId, examId, poseDirection: 'straight', poseAngle: 5 }, sToken);
  s8b.status === 200 && s8b.body.isSuspicious === false
    ? pass('8b', 'Head pose straight — no flag', { direction: s8b.body.poseDirection })
    : fail('8b', 'Head straight check failed', s8b.body);

  // ADMIN — All Face Logs
  const admin = await req('GET', '/api/face/admin/logs/' + attemptId, null, aToken);
  if (admin.status === 200) console.log('\n📊 Face Logs: total=' + admin.body.totalLogs + ' warnings=' + admin.body.totalWarnings);

  console.log('\n══════════════════════════════════════');
  console.log('     PHASE 5.4 TEST COMPLETE ✅');
  console.log('══════════════════════════════════════\n');
}

run().catch(err => { console.error('Test crashed:', err.message); process.exit(1); });
