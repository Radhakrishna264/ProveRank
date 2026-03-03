const axios = require('axios');
require('dotenv').config();
const BASE = 'http://localhost:3000';
let token = '';
const sleep = (ms) => new Promise(r => setTimeout(r, ms));
let passed = 0, failed = 0, failedList = [];

function ok(msg)   { console.log(`✅ PASS — ${msg}`); passed++; }
function fail(msg) { console.log(`❌ FAIL — ${msg}`); failed++; failedList.push(msg); }

async function login() {
  try {
    const res = await axios.post(`${BASE}/api/auth/login`, { email: 'admin@proverank.com', password: 'ProveRank@SuperAdmin123' });
    token = res.data.token;
    ok('SuperAdmin Login');
  } catch(e) { fail(`Login — ${e.message}`); process.exit(1); }
}

async function hit(method, url, body = null) {
  try {
    const cfg = { headers: { Authorization: `Bearer ${token}` } };
    const res = method === 'get' ? await axios.get(`${BASE}${url}`, cfg) : await axios[method](`${BASE}${url}`, body || {}, cfg);
    return res.status;
  } catch(e) { return e.response?.status || null; }
}

async function testPhase1_1() {
  console.log('\n━━ PHASE 1.1 — Auth System ━━');
  const r1 = await hit('get', '/api/auth/registration-fields');
  r1 !== 404 ? ok(`M2 — GET registration-fields (${r1})`) : fail('M2 — GET registration-fields NOT FOUND');
  const r2 = await hit('post', '/api/auth/registration-fields', { fieldName: `f_${Date.now()}`, label: 'Test', fieldType: 'text' });
  r2 !== 404 ? ok(`M2 — POST registration-fields (${r2})`) : fail('M2 — POST registration-fields NOT FOUND');
  const r3 = await hit('get', '/api/auth/me');
  r3 !== 404 ? ok(`M2/S49 — GET /me (${r3})`) : fail('M2 — GET /me NOT FOUND');
  const r4 = await hit('post', '/api/auth/2fa/enable');
  r4 !== 404 ? ok(`S49 — 2FA enable (${r4})`) : fail('S49 — enable NOT FOUND');
  const r5 = await hit('post', '/api/auth/2fa/verify', { otp: '000000' });
  r5 !== 404 ? ok(`S49 — 2FA verify (${r5})`) : fail('S49 — verify NOT FOUND');
  const r6 = await hit('post', '/api/auth/2fa/disable');
  r6 !== 404 ? ok(`S49 — 2FA disable (${r6})`) : fail('S49 — disable NOT FOUND');
  const r7 = await hit('post', '/api/auth/2fa/validate', { otp: '000000' });
  r7 !== 404 ? ok(`S49 — 2FA validate (${r7})`) : fail('S49 — validate NOT FOUND');
}

async function testPhase1_2() {
  console.log('\n━━ PHASE 1.2 — Role Protection ━━');
  // S37
  const a1 = await hit('post', '/api/admin/manage/create-admin', { name: 'T', email: `t_${Date.now()}@t.com`, password: 'Test@123' });
  a1 !== 404 ? ok(`S37 — create-admin (${a1})`) : fail('S37 — create-admin NOT FOUND');
  const a2 = await hit('get', '/api/admin/manage/admins');
  a2 !== 404 ? ok(`S37 — GET admins (${a2})`) : fail('S37 — GET admins NOT FOUND');
  // S72 — use a real admin ID
  const admins = await axios.get(`${BASE}/api/admin/manage/admins`, { headers: { Authorization: `Bearer ${token}` } }).catch(() => null);
  const adminId = admins?.data?.admins?.[0]?._id || '000000000000000000000001';
  const a3 = await hit('put', `/api/admin/manage/permissions/${adminId}`, { permissions: { canCreateExam: true } });
  a3 !== 404 ? ok(`S72 — permissions (${a3})`) : fail('S72 — permissions NOT FOUND');
  const a4 = await hit('put', `/api/admin/manage/freeze/${adminId}`, { frozen: false });
  a4 !== 404 ? ok(`S72 — freeze (${a4})`) : fail('S72 — freeze NOT FOUND');
  // S38
  const a5 = await hit('get', '/api/admin/manage/activity-logs');
  a5 !== 404 ? ok(`S38 — GET activity-logs (${a5})`) : fail('S38 — activity-logs NOT FOUND');
  const a6 = await hit('post', '/api/admin/manage/activity-logs', { action: 'TEST', details: 'test' });
  a6 !== 404 ? ok(`S38 — POST activity-logs (${a6})`) : fail('S38 — POST logs NOT FOUND');
  // S93
  const a7 = await hit('get', '/api/admin/manage/audit-trail');
  a7 !== 404 ? ok(`S93 — audit-trail (${a7})`) : fail('S93 — audit-trail NOT FOUND');
  // M4
  const a8 = await hit('post', `/api/admin/manage/impersonate/${adminId}`);
  a8 !== 404 ? ok(`M4 — impersonate (${a8})`) : fail('M4 — impersonate NOT FOUND');
}

async function testPhase1_3() {
  console.log('\n━━ PHASE 1.3 — Exam Model ━━');
  // S5
  const e1 = await hit('post', '/api/exams/series', { name: 'Test Series' });
  e1 !== 404 ? ok(`S5 — POST series (${e1})`) : fail('S5 — series NOT FOUND');
  const e2 = await hit('get', '/api/exams/series');
  e2 !== 404 ? ok(`S5 — GET series (${e2})`) : fail('S5 — GET series NOT FOUND');
  // S75
  const e3 = await hit('post', '/api/exams/template', { name: 'NEET', pattern: 'neet' });
  e3 !== 404 ? ok(`S75 — POST template (${e3})`) : fail('S75 — template NOT FOUND');
  const e4 = await hit('get', '/api/exams/templates');
  e4 !== 404 ? ok(`S75 — GET templates (${e4})`) : fail('S75 — GET templates NOT FOUND');
  // Get a real exam ID
  const exams = await axios.get(`${BASE}/api/exams`, { headers: { Authorization: `Bearer ${token}` } }).catch(() => null);
  const examId = exams?.data?.exams?.[0]?._id || exams?.data?.[0]?._id || '000000000000000000000001';
  console.log(`   Using examId: ${examId}`);
  // S85
  const e5 = await hit('post', `/api/exams/${examId}/whitelist`, { studentIds: [] });
  e5 !== 404 ? ok(`S85 — whitelist (${e5})`) : fail('S85 — whitelist NOT FOUND');
  // S26
  const e6 = await hit('get', `/api/exams/${examId}/sections`);
  e6 !== 404 ? ok(`S26 — sections (${e6})`) : fail('S26 — sections NOT FOUND');
  // S62
  const e7 = await hit('put', `/api/exams/${examId}/marking`, { correct: 4, wrong: -1 });
  e7 !== 404 ? ok(`S62 — marking (${e7})`) : fail('S62 — marking NOT FOUND');
  // S31
  const e8 = await hit('put', `/api/exams/${examId}/reattempt`, { maxAttempts: 2 });
  e8 !== 404 ? ok(`S31 — reattempt (${e8})`) : fail('S31 — reattempt NOT FOUND');
  // S96
  const e9 = await hit('get', `/api/exams/${examId}/countdown`);
  e9 !== 404 ? ok(`S96 — countdown (${e9})`) : fail('S96 — countdown NOT FOUND');
  // S66
  const e10 = await hit('post', '/api/admin/maintenance', { enabled: false });
  e10 !== 404 ? ok(`S66 — maintenance (${e10})`) : fail('S66 — maintenance NOT FOUND');
  const e11 = await hit('get', '/api/admin/maintenance');
  e11 !== 404 ? ok(`S66 — GET maintenance (${e11})`) : fail('S66 — GET maintenance NOT FOUND');
  // N21
  const e12 = await hit('get', '/api/admin/feature-flags');
  e12 !== 404 ? ok(`N21 — GET flags (${e12})`) : fail('N21 — GET flags NOT FOUND');
  const e13 = await hit('put', '/api/admin/feature-flags', { feature: 'darkMode', enabled: true });
  e13 !== 404 ? ok(`N21 — PUT flags (${e13})`) : fail('N21 — PUT flags NOT FOUND');
}

async function testPhase2_1() {
  console.log('\n━━ PHASE 2.1 — Question Intelligence ━━');
  // AI features
  const q1 = await hit('post', '/api/questions/ai/suggest-difficulty', { questionText: 'What is Newton law?' });
  q1 !== 404 ? ok(`AI-1 — suggest-difficulty (${q1})`) : fail('AI-1 — NOT FOUND');
  const q2 = await hit('post', '/api/questions/ai/classify', { questionText: 'What is photosynthesis?' });
  q2 !== 404 ? ok(`AI-2 — classify (${q2})`) : fail('AI-2 — NOT FOUND');
  const q3 = await hit('post', '/api/questions/ai/similarity', { questionText: 'Define Newton law' });
  q3 !== 404 ? ok(`AI-5 — similarity (${q3})`) : fail('AI-5 — NOT FOUND');
  // S33
  const q4 = await hit('get', '/api/questions/image-questions');
  q4 !== 404 ? ok(`S33 — image-questions (${q4})`) : fail('S33 — NOT FOUND');
  // Get real question ID
  const qs = await axios.get(`${BASE}/api/questions`, { headers: { Authorization: `Bearer ${token}` } }).catch(() => null);
  const qId = qs?.data?.questions?.[0]?._id || qs?.data?.[0]?._id || '000000000000000000000001';
  console.log(`   Using questionId: ${qId}`);
  // S35
  const q5 = await hit('get', `/api/questions/${qId}/usage`);
  q5 !== 404 ? ok(`S35 — usage (${q5})`) : fail('S35 — usage NOT FOUND');
  // S104
  const q6 = await hit('get', '/api/questions/pyq');
  q6 !== 404 ? ok(`S104 — PYQ (${q6})`) : fail('S104 — NOT FOUND');
  // AI-8, AI-10
  const q7 = await hit('post', '/api/questions/ai/translate', { questionText: 'What is force?', targetLang: 'hindi' });
  q7 !== 404 ? ok(`AI-8 — translate (${q7})`) : fail('AI-8 — NOT FOUND');
  const q8 = await hit('post', '/api/questions/ai/explanation', { questionText: 'What is force?' });
  q8 !== 404 ? ok(`AI-10 — explanation (${q8})`) : fail('AI-10 — NOT FOUND');
  // N7
  const q9 = await hit('get', '/api/questions/pending-approval');
  q9 !== 404 ? ok(`N7 — pending-approval (${q9})`) : fail('N7 — NOT FOUND');
  const q10 = await hit('put', `/api/questions/${qId}/approve`, { action: 'approve' });
  q10 !== 404 ? ok(`N7 — approve (${q10})`) : fail('N7 — approve NOT FOUND');
  // M11
  const q11 = await hit('post', '/api/questions/import/xml', { xmlData: '<quiz><question></question></quiz>' });
  q11 !== 404 ? ok(`M11 — XML import (${q11})`) : fail('M11 — NOT FOUND');
  // MCQ/MSQ check-answer
  const q12 = await hit('post', '/api/questions/check-answer', { questionId: qId, type: 'SCQ', selectedOption: 'A' });
  q12 !== 404 ? ok(`MCQ — check-answer (${q12})`) : fail('MCQ — check-answer NOT FOUND');
  const q13 = await hit('post', '/api/questions/check-answer', { questionId: qId, type: 'MSQ', selectedOptions: ['A','C'] });
  q13 !== 404 ? ok(`MSQ — check-answer (${q13})`) : fail('MSQ — check-answer NOT FOUND');
}

async function run() {
  console.log('\n🔍 ProveRank — Complete Missing Features Test');
  console.log('Phases: 1.1 | 1.2 | 1.3 | 2.1\n');
  await login(); await sleep(300);
  await testPhase1_1(); await sleep(200);
  await testPhase1_2(); await sleep(200);
  await testPhase1_3(); await sleep(200);
  await testPhase2_1();
  console.log('\n══════════════════════════════════════');
  console.log(`✅ PASSED: ${passed} | ❌ FAILED: ${failed}`);
  console.log('══════════════════════════════════════');
  if (failedList.length > 0) {
    console.log('\n⚠️  Failed:');
    failedList.forEach((f,i) => console.log(`  ${i+1}. ${f}`));
  } else {
    console.log('\n🎉 Sab features present! Stage 3 ready!');
  }
  process.exit(0);
}
run().catch(e => { console.error('Fatal:', e.message); process.exit(1); });
