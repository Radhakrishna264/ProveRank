const mongoose = require('mongoose');

// ─── CONFIG ────────────────────────────────────────────────────────────
const BASE_URL = 'http://localhost:3000';
const ADMIN_EMAIL = 'admin@proverank.com';
const ADMIN_PASS = 'ProveRank@SuperAdmin123';
const STUDENT_PASS = 'ProveRank@123';

// ─── HELPERS ───────────────────────────────────────────────────────────
const fetch = (...args) => import('node-fetch').then(({default: f}) => f(...args));

let adminToken = '';
let studentToken = '';
let studentId = '';
let examId = '';
let examInstanceId = '';
let attemptId = '';

const log = (step, status, msg) => {
  const icon = status === 'PASS' ? '✅' : status === 'FAIL' ? '❌' : '⚠️';
  console.log(`\n${icon} Step ${step}: ${msg}`);
};

async function post(url, body, token) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;
  const res = await fetch(BASE_URL + url, { method: 'POST', headers, body: JSON.stringify(body) });
  const data = await res.json().catch(() => ({}));
  return { status: res.status, data };
}

async function get(url, token) {
  const headers = {};
  if (token) headers['Authorization'] = `Bearer ${token}`;
  const res = await fetch(BASE_URL + url, { method: 'GET', headers });
  const data = await res.json().catch(() => ({}));
  return { status: res.status, data };
}

// ─── SETUP: Login + Get IDs ────────────────────────────────────────────
async function setup() {
  console.log('\n🔧 SETUP: Admin login + exam/student fetch...');

  // Admin login
  const adminLogin = await post('/api/auth/login', { email: ADMIN_EMAIL, password: ADMIN_PASS });
  if (!adminLogin.data.token) {
    console.log('❌ SETUP FAIL: Admin login failed. Server chal raha hai?');
    console.log('   Response:', JSON.stringify(adminLogin.data));
    process.exit(1);
  }
  adminToken = adminLogin.data.token;
  console.log('✅ Admin login OK');

  // Get a student - hardcoded
  const arr = [{ _id: "69a79bf3cf258d0f95868ddb", email: "student@proverank.com" }];
  // studentList patch applied
  // const arr2 = [];
  if (arr.length === 0) {
    console.log("No student");
    process.exit(1);
  }
  const student = arr[0];
  studentId = student._id;
  const studentEmail = student.email;
  console.log(`✅ Student mila: ${studentEmail}`);

  // Student login
  const stuLogin = await post('/api/auth/login', { email: studentEmail, password: STUDENT_PASS });
  if (stuLogin.data.token) {
    studentToken = stuLogin.data.token;
    console.log('✅ Student login OK');
  } else {
    console.log('⚠️  Student login fail — default password try karo manually');
  }

  // Get an exam
  const exams = await get('/api/exams', adminToken);
  const examList = Array.isArray(exams.data) ? exams.data : exams.data.exams || [];
  if (examList.length === 0) {
    console.log('⚠️  Koi exam nahi mila. Admin se ek exam create karo.');
    process.exit(1);
  }
  examId = examList[0]._id;
  console.log(`✅ Exam mila: ${examList[0].title || examId}`);

  // Get exam instance
  const inst = await get('/api/exam-instances', adminToken);
  const instList = Array.isArray(inst.data) ? inst.data : inst.data.instances || [];
  if (instList.length > 0) {
    examInstanceId = instList[0]._id;
    console.log(`✅ ExamInstance mila: ${examInstanceId}`);
  } else {
    console.log('⚠️  ExamInstance nahi mila — Steps 2,10 skip honge');
  }
}

// ─── TESTS ─────────────────────────────────────────────────────────────
async function runTests() {

  // STEP 1 — Student Rank Prediction (S97)
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  const r1 = await get(`/api/exams/${examId}/rank-prediction`, studentToken);
  if (r1.status === 200) {
    log(1, 'PASS', `Rank Prediction (S97) — ${JSON.stringify(r1.data).slice(0,80)}`);
  } else {
    log(1, 'FAIL', `Rank Prediction — HTTP ${r1.status} | ${JSON.stringify(r1.data).slice(0,100)}`);
  }

  // STEP 2 — Exam Waiting Room (M6)
  const waitUrl = examInstanceId
    ? `/api/exam-instances/${examInstanceId}/waiting-room`
    : `/api/exams/${examId}/waiting-room`;
  const r2 = await get(waitUrl, studentToken);
  if (r2.status === 200) {
    log(2, 'PASS', `Waiting Room (M6) — ${JSON.stringify(r2.data).slice(0,80)}`);
  } else {
    log(2, 'FAIL', `Waiting Room — HTTP ${r2.status} | ${JSON.stringify(r2.data).slice(0,100)}`);
  }

  // STEP 3 — Instructions Page
  const r3 = await get(`/api/exams/${examId}/instructions`, studentToken);
  if (r3.status === 200) {
    log(3, 'PASS', `Instructions Page — OK`);
  } else {
    log(3, 'FAIL', `Instructions — HTTP ${r3.status} | ${JSON.stringify(r3.data).slice(0,100)}`);
  }

  // STEP 4 — T&C Acceptance (S91)
  const r4 = await post(`/api/exams/${examId}/accept-terms`, { accepted: true }, studentToken);
  if (r4.status === 200 || r4.status === 201) {
    log(4, 'PASS', `T&C Accepted (S91) — OK`);
  } else {
    log(4, 'FAIL', `T&C — HTTP ${r4.status} | ${JSON.stringify(r4.data).slice(0,100)}`);
  }

  // STEP 4b — T&C Rejected = Block
  const r4b = await post(`/api/exams/${examId}/accept-terms`, { accepted: false }, studentToken);
  if (r4b.status === 400 || r4b.status === 403) {
    log('4b', 'PASS', `T&C Reject = Student blocked (S91) — HTTP ${r4b.status}`);
  } else {
    log('4b', 'FAIL', `T&C Reject check — HTTP ${r4b.status} | Expected 400/403`);
  }

  // STEP 5 — Attempt Limit Check (S31)
  const r5 = await get(`/api/exams/${examId}/attempt-limit`, studentToken);
  if (r5.status === 200) {
    log(5, 'PASS', `Attempt Limit (S31) — ${JSON.stringify(r5.data).slice(0,80)}`);
  } else {
    log(5, 'FAIL', `Attempt Limit — HTTP ${r5.status} | ${JSON.stringify(r5.data).slice(0,100)}`);
  }

  // STEP 6 — Create Attempt Record
  const r4fix = await post(`/api/exams/${examId}/accept-terms`, { accepted: true }, studentToken);
  const r6 = await post(`/api/exams/${examId}/start-attempt`, { validateOnly: false }, studentToken);
  if (r6.status === 200 || r6.status === 201) {
    attemptId = r6.data.attemptId || r6.data._id || r6.data.attempt?._id || '';
    log(6, 'PASS', `Attempt Created — ID: ${attemptId}`);
  } else {
    log(6, 'FAIL', `Create Attempt — HTTP ${r6.status} | ${JSON.stringify(r6.data).slice(0,120)}`);
  }

  // STEP 7 — IP Address recorded (S20)
  if (attemptId) {
    const r7 = await get(`/api/exams/attempt/${attemptId}`, studentToken);
    const ip = r7.data?.ipAddress || r7.data?.attempt?.ipAddress || r7.data?.ip;
    if (ip) {
      log(7, 'PASS', `IP Address recorded (S20) — ${ip}`);
    } else {
      log(7, 'FAIL', `IP not found in attempt record — ${JSON.stringify(r7.data).slice(0,100)}`);
    }
  } else {
    log(7, 'FAIL', 'IP check skip — Step 6 mein attempt nahi bana');
  }

  // STEP 8 — Start Timestamp
  if (attemptId) {
    const r8 = await get(`/api/exams/attempt/${attemptId}`, studentToken);
    const ts = r8.data?.startTime || r8.data?.attempt?.startTime || r8.data?.createdAt;
    if (ts) {
      log(8, 'PASS', `Start Timestamp recorded — ${ts}`);
    } else {
      log(8, 'FAIL', `startTime nahi mila — ${JSON.stringify(r8.data).slice(0,100)}`);
    }
  } else {
    log(8, 'FAIL', 'Timestamp check skip — No attempt ID');
  }

  // STEP 9 — Exam Access Whitelist (S85)
  const r9 = await get(`/api/exams/${examId}/whitelist-check`, studentToken);
  if (r9.status === 200) {
    log(9, 'PASS', `Whitelist Check (S85) — ${JSON.stringify(r9.data).slice(0,80)}`);
  } else {
    log(9, 'FAIL', `Whitelist — HTTP ${r9.status} | ${JSON.stringify(r9.data).slice(0,100)}`);
  }

  // STEP 10 — Admit Card Verification (S106)
  const admitUrl = examInstanceId
    ? `/api/exam-instances/${examInstanceId}/verify-admit-card`
    : `/api/exams/${examId}/verify-admit-card`;
  const r10 = await post(admitUrl, { studentId }, studentToken);
  if (r10.status === 200) {
    log(10, 'PASS', `Admit Card Verified (S106) — OK`);
  } else {
    log(10, 'FAIL', `Admit Card — HTTP ${r10.status} | ${JSON.stringify(r10.data).slice(0,100)}`);
  }

  // STEP 11 — Fullscreen Force Mode (S32)
  const r11 = await get(`/api/exams/${examId}/fullscreen-setting`, studentToken);
  if (r11.status === 200) {
    const fs = r11.data?.fullscreenForce ?? r11.data?.fullscreen ?? r11.data?.exam?.fullscreenForce;
    if (fs !== undefined) {
      log(11, 'PASS', `Fullscreen Force (S32) — fullscreenForce: ${fs}`);
    } else {
      log(11, 'FAIL', `Fullscreen route OK lekin fullscreenForce field nahi mili — ${JSON.stringify(r11.data).slice(0,100)}`);
    }
  } else {
    log(11, 'FAIL', `Fullscreen — HTTP ${r11.status} | ${JSON.stringify(r11.data).slice(0,100)}`);
  }

  // ─── SUMMARY ─────────────────────────────────────────────────────────
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('📊 PHASE 4.1 TEST COMPLETE');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('✅ = PASS  ❌ = FAIL  ⚠️  = Warning');
  console.log('\nFAIL wale steps ka error message upar dekho.');
  console.log('Exact HTTP status + response copy karke share karo.\n');
}

// ─── MAIN ──────────────────────────────────────────────────────────────
(async () => {
  try {
    await setup();
    // Cleanup before tests
  const mng = require('mongoose');
  await mng.connect(process.env.MONGO_URI);
  await mng.connection.db.collection('attempts').deleteMany({});
  await mng.connection.db.collection('students').updateMany({}, { $unset: { termsAccepted: 1 } });
  await mng.disconnect();
  console.log('🧹 DB Cleanup done');

  await runTests();
  } catch (err) {
    console.error('\n💥 Script Error:', err.message);
  }
  process.exit(0);
})();
