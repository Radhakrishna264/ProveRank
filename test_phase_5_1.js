const http = require('http');
const mongoose = require('mongoose');

const BASE = 'http://localhost:3000';
const MONGO_URI = process.env.MONGO_URI;

function req(method, path, body, token) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = 'Bearer ' + token;
    if (data) headers['Content-Length'] = Buffer.byteLength(data);
    const options = { hostname: 'localhost', port: 3000, path, method, headers };
    const r = http.request(options, (res) => {
      let d = '';
      res.on('data', chunk => d += chunk);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(d) }); }
        catch { resolve({ status: res.statusCode, body: d }); }
      });
    });
    r.on('error', reject);
    if (data) r.write(data);
    r.end();
  });
}

function pass(step, msg, data) {
  console.log('✅ PASS Step ' + step + ' — ' + msg);
  if (data) console.log('   →', JSON.stringify(data).substring(0, 120));
}
function fail(step, msg, data) {
  console.log('❌ FAIL Step ' + step + ' — ' + msg);
  if (data) console.log('   →', JSON.stringify(data).substring(0, 200));
}

async function run() {
  console.log('\n══════════════════════════════════════');
  console.log('  PHASE 5.1 TEST — Anti-Cheat Backend');
  console.log('══════════════════════════════════════\n');

  // LOGIN
  const sLogin = await req('POST', '/api/auth/login', { email: 'student@proverank.com', password: 'ProveRank@123' });
  if (!sLogin.body.token) { console.log('❌ Student login failed:', sLogin.body); return; }
  const sToken = sLogin.body.token;
  const sId = JSON.parse(Buffer.from(sToken.split('.')[1], 'base64').toString()).id;
  console.log('🔐 Student logged in | ID:', sId);

  const aLogin = await req('POST', '/api/auth/login', { email: 'admin@proverank.com', password: 'ProveRank@SuperAdmin123' });
  if (!aLogin.body.token) { console.log('❌ Admin login failed:', aLogin.body); return; }
  const aToken = aLogin.body.token;
  console.log('🔐 Admin logged in\n');

  // GET ACTIVE ATTEMPT FROM DB
  let attemptId, examId;
  try {
    await mongoose.connect(MONGO_URI);
    const Attempt = require('./src/models/Attempt');
    const att = await Attempt.findOne({ status: 'active' }).sort({ createdAt: -1 });
    if (att) {
      attemptId = att._id.toString();
      examId = att.examId.toString();
      console.log('📋 Active attempt found:', attemptId);
    } else {
      // No active attempt — start one
      console.log('⚠️  No active attempt — starting one...');
      const Exam = require('./src/models/Exam');
      const exam = await Exam.findOne({});
      await mongoose.connection.close();
      if (!exam) { console.log('❌ No exam found in DB'); return; }
      examId = exam._id.toString();
      const startRes = await req('POST', '/api/exams/' + examId + '/start-attempt', {}, sToken);
      if (!startRes.body.attemptId) { console.log('❌ Could not start attempt:', startRes.body); return; }
      attemptId = startRes.body.attemptId;
      console.log('✅ New attempt started:', attemptId);
    }
    if (mongoose.connection.readyState === 1) await mongoose.connection.close();
  } catch (err) {
    console.log('DB error:', err.message);
    if (mongoose.connection.readyState === 1) await mongoose.connection.close();
    return;
  }

  console.log('');

  // STEP 1 — Tab Switch
  const s1 = await req('POST', '/api/anticheat/tab-switch', { attemptId, examId, metadata: { from: 'exam', to: 'other_tab' } }, sToken);
  s1.status === 200 && s1.body.warningCount !== undefined
    ? pass(1, 'Tab Switch logged', { warningCount: s1.body.warningCount, autoSubmitted: s1.body.autoSubmitted })
    : fail(1, 'Tab Switch failed', s1.body);

  // STEP 2 — Window Blur
  const s2 = await req('POST', '/api/anticheat/window-blur', { attemptId, examId, metadata: { duration: 3.5 } }, sToken);
  s2.status === 200 && s2.body.warningCount !== undefined
    ? pass(2, 'Window Blur logged', { warningCount: s2.body.warningCount })
    : fail(2, 'Window Blur failed', s2.body);

  // STEP 3 — Warning Counter
  const s3 = await req('GET', '/api/anticheat/warning-count/' + attemptId, null, sToken);
  s3.status === 200 && s3.body.warningCount !== undefined
    ? pass(3, 'Warning Counter working', { count: s3.body.warningCount, remaining: s3.body.remainingWarnings, maxWarnings: s3.body.maxWarnings })
    : fail(3, 'Warning Counter failed', s3.body);

  // STEP 4 — Fullscreen Exit (S32)
  const s4 = await req('POST', '/api/anticheat/fullscreen-exit', { attemptId, examId, metadata: { screen: 'exited' } }, sToken);
  s4.status === 200
    ? pass(4, 'Fullscreen exit logged (S32)', { action: s4.body.action, warningCount: s4.body.warningCount })
    : fail(4, 'Fullscreen Exit failed', s4.body);

  const s4b = await req('GET', '/api/anticheat/fullscreen-status/' + attemptId, null, sToken);
  if (s4b.status === 200) console.log('   → Fullscreen exit count:', s4b.body.fullscreenExitCount);

  // STEP 5 — Watermark (S76)
  const s5 = await req('GET', '/api/anticheat/watermark/' + attemptId, null, sToken);
  s5.status === 200 && s5.body.watermark
    ? pass(5, 'Watermark ready (S76)', { text: s5.body.watermark.watermarkText })
    : fail(5, 'Watermark failed', s5.body);

  // STEP 6 — Session Lock (S112)
  const s6 = await req('POST', '/api/anticheat/session-lock-check', { attemptId, examId, deviceFingerprint: 'android_' + Date.now() }, sToken);
  s6.status === 200 && s6.body.sessionLocked === false
    ? pass(6, 'Session Lock — single device OK (S112)', { sessionLocked: s6.body.sessionLocked })
    : s6.status === 403
    ? pass(6, 'Session Lock BLOCKING multi-device (S112)', { locked: true })
    : fail(6, 'Session Lock failed', s6.body);

  // STEP 7 — N14 Suspicious Patterns
  const s7 = await req('GET', '/api/anticheat/suspicious-patterns/' + attemptId, null, aToken);
  s7.status === 200 && s7.body.adminAlert !== undefined
    ? pass(7, 'N14 Pattern Detector working', { isSuspicious: s7.body.isSuspicious, alert: s7.body.adminAlert, flags: s7.body.totalFlagsFound })
    : fail(7, 'N14 Detector failed', s7.body);

  // STEP 8 — AI-6 Integrity Score
  const s8 = await req('GET', '/api/anticheat/integrity-score/' + attemptId, null, sToken);
  s8.status === 200 && s8.body.integrityScore !== undefined
    ? pass(8, 'AI-6 Integrity Score calculated', { score: s8.body.integrityScore, riskLevel: s8.body.riskLevel, interpretation: s8.body.interpretation })
    : fail(8, 'AI-6 Score failed', s8.body);

  // BONUS — Admin Alerts
  const bonus = await req('GET', '/api/anticheat/admin/alerts', null, aToken);
  if (bonus.status === 200) console.log('\n📊 Admin Alerts:', bonus.body.totalAlerts, 'entries found');

  console.log('\n══════════════════════════════════════');
  console.log('       PHASE 5.1 TEST COMPLETE ✅');
  console.log('══════════════════════════════════════\n');
}

run().catch(err => { console.error('Test crashed:', err.message); process.exit(1); });
