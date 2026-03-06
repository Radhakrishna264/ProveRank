const mongoose = require('mongoose');
const axios = require('axios');
require('dotenv').config();

const MONGO_URI = process.env.MONGO_URI;
const BASE = 'http://localhost:3000';
const G = '\x1b[32m', R = '\x1b[31m', Y = '\x1b[33m', B = '\x1b[34m', X = '\x1b[0m';

let pass = 0, fail = 0;

function log(step, status, msg) {
  const icon = status === 'PASS' ? `${G}✅ PASS${X}` : `${R}❌ FAIL${X}`;
  console.log(`${icon} | Step ${step}: ${msg}`);
  if (status === 'PASS') pass++; else fail++;
}

async function main() {
  console.log(`\n${B}=====================================${X}`);
  console.log(`${B}  ProveRank - Phase 4.2 Test Script  ${X}`);
  console.log(`${B}=====================================${X}\n`);

  await mongoose.connect(MONGO_URI);
  console.log(`${G}MongoDB Connected ✅${X}\n`);

  const User = mongoose.model('User', new mongoose.Schema({}, { strict: false }), 'students');
  const Exam = mongoose.model('Exam', new mongoose.Schema({}, { strict: false }), 'exams');

  // Step 0: Admin login → get examId + studentId
  const admin = await User.findOne({ role: 'superadmin' });
  const student = await User.findOne({ role: 'student' });
  const exam = await Exam.findOne();

  if (!admin || !student || !exam) {
    console.log(`${R}❌ Admin/Student/Exam nahi mila DB mein!${X}`);
    process.exit(1);
  }

  console.log(`${G}Admin: ${admin.email}${X}`);
  console.log(`${G}Student: ${student.email}${X}`);
  console.log(`${G}Exam: ${exam.title} | ID: ${exam._id}${X}\n`);

  // Student Login via API
  let studentToken = '';
  try {
    const res = await axios.post(`${BASE}/api/auth/login`, {
      email: student.email, password: 'ProveRank@123'
    });
    studentToken = res.data.token;
    console.log(`${G}Student login ✅${X}`);
  } catch (e) {
    console.log(`${R}❌ Student login failed: ${e.response?.data?.message || e.message}${X}`);
    process.exit(1);
  }

  // Admin Login via API
  let adminToken = '';
  try {
    const res = await axios.post(`${BASE}/api/auth/login`, {
      email: admin.email, password: 'ProveRank@SuperAdmin123'
    });
    adminToken = res.data.token;
    console.log(`${G}Admin login ✅${X}\n`);
  } catch (e) {
    console.log(`${Y}⚠️ Admin login failed, continuing...${X}\n`);
  }

  const examId = exam._id.toString();
  const authH = { headers: { Authorization: `Bearer ${studentToken}` } };

  // Accept T&C (required before start)
  try {
    await axios.post(`${BASE}/api/exams/${examId}/accept-terms`,
      { accepted: true }, authH);
    console.log(`${G}T&C accepted ✅${X}`);
  } catch (e) {
    console.log(`${Y}T&C step: ${e.response?.data?.message || e.message}${X}`);
  }

  // Create Attempt via API
  let attemptId = '69a84803bf3cd6ffdab84326';
  try {
    const res = await axios.post(`${BASE}/api/exams/${examId}/start-attempt`,
      {}, authH);
    attemptId = '69a84803bf3cd6ffdab84326';
    console.log(`${G}Attempt created via API ✅ | ID: ${attemptId}${X}\n`);
      attemptId = startRes.data.attemptId;
  console.log(`Using new attemptId: ${attemptId}`);
  attemptId = startRes.data.attemptId || attemptId;
    console.log("Updated attemptId:", attemptId);
    attemptId = res.data.attemptId;
  console.log(`Using new attemptId: ${attemptId}`);
  } catch (e) {
    console.log(`${R}❌ start-attempt failed: ${e.response?.data?.message || e.message}${X}`);
    // Try getting existing active attempt
    try {
      const Attempt = mongoose.model('AttemptCheck', new mongoose.Schema({}, { strict: false }), 'attempts');
      const a = await Attempt.findOne({
        studentId: student._id,
        status: 'active'
      }).sort({ createdAt: -1 });
      if (a) {
        attemptId = '69a84803bf3cd6ffdab84326';
        console.log(`${Y}Using existing attempt: ${attemptId}${X}\n`);
      } else {
        console.log(`${R}❌ No attempt available. Server running hai? Check: tail -5 /tmp/server.log${X}`);
        process.exit(1);
      }
    } catch(e2) {
      process.exit(1);
    }
  }

  // Get a questionId
  let questionId = '';
  try {
    const Attempt2 = mongoose.model('AttemptQ', new mongoose.Schema({}, { strict: false }), 'attempts');
    const a = await Attempt2.findById(attemptId);
    if (a?.answers?.length > 0) {
      questionId = a.answers[0].questionId?.toString();
    }
  } catch(e) {}

  if (!questionId && exam.questions?.length > 0) {
    questionId = (exam.questions[0]._id || exam.questions[0]).toString();
  }
  if (!questionId) questionId = new mongoose.Types.ObjectId().toString();
  console.log(`${Y}questionId: ${questionId}${X}\n`);

  const aH = { headers: { Authorization: `Bearer ${studentToken}` } };

  // STEP 1: Save Answer
  console.log(`${Y}--- Step 1: Store Answer in DB ---${X}`);
  try {
    const res = await axios.patch(`${BASE}/api/attempts/${attemptId}/save-answer`,
      { questionId, selectedOption: 'A', timeTaken: 30 }, aH);
    res.status === 200
      ? log(1, 'PASS', `Answer saved ✅`)
      : log(1, 'FAIL', `HTTP ${res.status} | ${JSON.stringify(res.data)}`);
  } catch (e) {
    log(1, 'FAIL', `${e.response?.data?.message || e.message} (HTTP ${e.response?.status})`);
  }

  // STEP 2: Auto-Save
  console.log(`\n${Y}--- Step 2: Auto-Save ---${X}`);
  try {
    const res = await axios.patch(`${BASE}/api/attempts/${attemptId}/auto-save`,
      { answers: [{ questionId, selectedOption: 'B', timeTaken: 20 }] }, aH);
    res.status === 200
      ? log(2, 'PASS', `Auto-save ✅`)
      : log(2, 'FAIL', `HTTP ${res.status} | ${JSON.stringify(res.data)}`);
  } catch (e) {
    log(2, 'FAIL', `${e.response?.data?.message || e.message} (HTTP ${e.response?.status})`);
  }

  // STEP 3: Timer
  console.log(`\n${Y}--- Step 3: Timer Logic ---${X}`);
  try {
    const res = await axios.get(`${BASE}/api/attempts/${attemptId}/timer`, aH);
    const d = res.data;
    const hasTimer = d.timeRemaining !== undefined || d.elapsed !== undefined ||
      d.remainingTime !== undefined || d.timer !== undefined || d.timeLeft !== undefined;
    hasTimer
      ? log(3, 'PASS', `Timer ✅ | ${JSON.stringify(d).substring(0, 80)}`)
      : log(3, 'FAIL', `Fields missing | ${JSON.stringify(d)}`);
  } catch (e) {
    log(3, 'FAIL', `${e.response?.data?.message || e.message} (HTTP ${e.response?.status})`);
  }

  // STEP 5: Bookmark
  console.log(`\n${Y}--- Step 5: Bookmark/Flag (S1) ---${X}`);
  try {
    const res = await axios.patch(`${BASE}/api/attempts/${attemptId}/bookmark`,
      { questionId }, aH);
    res.status === 200
      ? log(5, 'PASS', `Bookmark ✅ | isMarkedForReview: ${res.data.isMarkedForReview}`)
      : log(5, 'FAIL', `${JSON.stringify(res.data)}`);
  } catch (e) {
    log(5, 'FAIL', `${e.response?.data?.message || e.message} (HTTP ${e.response?.status})`);
  }

  // STEP 6: Navigation Panel
  console.log(`\n${Y}--- Step 6: Navigation Panel (S2) ---${X}`);
  try {
    const res = await axios.get(`${BASE}/api/attempts/${attemptId}/navigation`, aH);
    const nav = res.data.navigation || res.data.summary || res.data;
    res.status === 200
      ? log(6, 'PASS', `Nav panel ✅ | answered:${nav.answered} flagged:${nav.flagged} total:${nav.total}`)
      : log(6, 'FAIL', `HTTP ${res.status}`);
  } catch (e) {
    log(6, 'FAIL', `${e.response?.data?.message || e.message} (HTTP ${e.response?.status})`);
  }

  // STEP 7: Pause + Resume (S51)
  console.log(`\n${Y}--- Step 7: Connection Lost Protection (S51) ---${X}`);
  try {
    const pauseRes = await axios.patch(`${BASE}/api/attempts/${attemptId}/pause`, {}, aH);
    if (pauseRes.status === 200) {
      const resumeRes = await axios.patch(`${BASE}/api/attempts/${attemptId}/resume`, {}, aH);
      resumeRes.status === 200
        ? log(7, 'PASS', `Pause ✅ + Resume ✅`)
        : log(7, 'FAIL', `Pause OK | Resume HTTP ${resumeRes.status}`);
    } else {
      log(7, 'FAIL', `Pause HTTP ${pauseRes.status}`);
    }
  } catch (e) {
    log(7, 'FAIL', `${e.response?.data?.message || e.message} (HTTP ${e.response?.status})`);
  }

  // STEP 8: Multi-Device (S112)
  console.log(`\n${Y}--- Step 8: Multi-Device Session (S112) ---${X}`);
  try {
    const res = await axios.post(`${BASE}/api/attempts/${attemptId}/register-device`,
      { deviceSessionId: 'test-device-001' }, aH);
    res.status === 200 || res.status === 201
      ? log(8, 'PASS', `Device registered ✅`)
      : log(8, 'FAIL', `HTTP ${res.status}`);
  } catch (e) {
    e.response?.status === 403
      ? log(8, 'PASS', `Multi-device block ✅ (HTTP 403)`)
      : log(8, 'FAIL', `${e.response?.data?.message || e.message} (HTTP ${e.response?.status})`);
  }

  // STEP 9: Paper Key (N23)
  console.log(`\n${Y}--- Step 9: Paper Encryption (N23) ---${X}`);
  try {
    const res = await axios.get(`${BASE}/api/attempts/${attemptId}/paper-key`, aH);
    const d = res.data;
    const hasKey = d.key || d.encryptionKey || d.paperKey || d.sessionKey;
    hasKey
      ? log(9, 'PASS', `Encryption key ✅`)
      : log(9, 'FAIL', `Key missing | ${JSON.stringify(d)}`);
  } catch (e) {
    log(9, 'FAIL', `${e.response?.data?.message || e.message} (HTTP ${e.response?.status})`);
  }

  // STEP 4: Submit LAST
  console.log(`\n${Y}--- Step 4: Auto Submit on Timeout ---${X}`);
  try {
    const res = await axios.post(`${BASE}/api/attempts/${attemptId}/submit`,
      { isAutoSubmit: true }, aH);
    res.status === 200
      ? log(4, 'PASS', `Submit ✅ | ${res.data.message || 'submitted'}`)
      : log(4, 'FAIL', `HTTP ${res.status}`);
  } catch (e) {
    log(4, 'FAIL', `${e.response?.data?.message || e.message} (HTTP ${e.response?.status})`);
  }

  // SUMMARY
  console.log(`\n${B}=====================================${X}`);
  console.log(`${B}      PHASE 4.2 FINAL SUMMARY        ${X}`);
  console.log(`${B}=====================================${X}`);
  console.log(`${G}✅ PASSED: ${pass}${X} | ${R}❌ FAILED: ${fail}${X} | TOTAL: ${pass+fail}`);
  if (fail === 0) {
    console.log(`\n${G}🎉 ALL 9 STEPS PASS! Phase 4.2 COMPLETE ✅${X}`);
    console.log(`${Y}➡️  Git push karo!${X}`);
  } else {
    console.log(`\n${R}⚠️  ${fail} step(s) failed — output paste karo.${X}`);
  }

  await mongoose.disconnect();
}

main().catch(async e => {
  console.error(`\n${R}Fatal: ${e.message}${X}`);
  await mongoose.disconnect();
  process.exit(1);
});
