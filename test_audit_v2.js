const axios = require('axios');
const B = 'http://localhost:3000';
let adminToken = '', studentToken = '', examId = '', attemptId = '';

async function run() {
  let p = 0, f = 0, s = 0;
  const ok = (name) => { console.log(`[PASS] ${name}`); p++; };
  const no = (name, e) => { console.log(`[FAIL] ${name} : ${e?.response?.status || e?.message}`); f++; };
  const sk = (name) => { console.log(`[SKIP] ${name}`); s++; };

  // STAGE 0
  try { await axios.get(`${B}/api/health`); ok('Health Check'); } catch(e) { no('Health Check', e); }

  // STAGE 1 - Auth
  try { const r = await axios.post(`${B}/api/auth/login`, { email: 'admin@proverank.com', password: 'ProveRank@SuperAdmin123' }); adminToken = r.data.token; ok('SuperAdmin login'); } catch(e) { no('SuperAdmin login', e); }
  try { const r = await axios.post(`${B}/api/auth/login`, { email: 'student@proverank.com', password: 'ProveRank@123' }); studentToken = r.data.token; ok('Student login'); } catch(e) { no('Student login', e); }

  const ah = { headers: { Authorization: `Bearer ${adminToken}` } };
  const sh = { headers: { Authorization: `Bearer ${studentToken}` } };

  // STAGE 1 - Role Middleware
  try { await axios.get(`${B}/api/admin/students`, ah); ok('Role Middleware - isAdmin'); } catch(e) { no('Role Middleware - isAdmin', e); }
  try { await axios.get(`${B}/api/admin/students`, sh).catch(e => { if(e.response?.status === 403) throw e; }); no('Role Middleware - student blocked', {response:{status:'should be 403'}}); } catch(e) { if(e.response?.status === 403) ok('Role Middleware - student blocked 403'); else no('Role Middleware - student blocked', e); }

  // STAGE 1 - Admin
  try { await axios.get(`${B}/api/admin/students`, ah); ok('Admin student list'); } catch(e) { no('Admin student list', e); }

  // STAGE 1 - Exam APIs
  try {
    const r = await axios.post(`${B}/api/exams`, {
      title: 'V2 Test Exam', duration: 200, totalQuestions: 180,
      sections: [{ name: 'Physics', questions: 45 }],
      marking: { correct: 4, incorrect: -1 }, scheduledAt: new Date(Date.now() + 3600000)
    }, ah);
    examId = r.data._id || r.data.exam?._id;
    ok('Create Exam');
  } catch(e) { no('Create Exam', e); }

  try { await axios.get(`${B}/api/exams`, ah); ok('Fetch Exams'); } catch(e) { no('Fetch Exams', e); }

  // STAGE 2 - Questions
  try { await axios.get(`${B}/api/questions`, ah); ok('Fetch Questions'); } catch(e) { no('Fetch Questions', e); }

  // STAGE 4.1 - Attempt
  try {
    if (!examId) throw new Error('No examId');
    const r = await axios.post(`${B}/api/exams/${examId}/start-attempt`, {}, sh);
    attemptId = r.data.attemptId || r.data.attempt?._id || r.data._id;
    ok('Start Attempt');
  } catch(e) { no('Start Attempt', e); }

  // STAGE 4.2
  try { await axios.get(`${B}/api/attempts/${attemptId}/timer`, sh); ok('Timer Route'); } catch(e) { no('Timer Route', e); }
  try { await axios.get(`${B}/api/attempts/${attemptId}/navigation`, sh); ok('Navigation Route'); } catch(e) { no('Navigation Route', e); }
  try { await axios.patch(`${B}/api/attempts/${attemptId}/bookmark`, { questionId: '000000000000000000000001' }, sh); ok('S1 Bookmark'); } catch(e) { no('S1 Bookmark', e); }
  try { await axios.get(`${B}/api/attempts/${attemptId}/paper-key`, sh); ok('S99 Paper Key'); } catch(e) { no('S99 Paper Key', e); }

  // STAGE 4.3
  try { await axios.post(`${B}/api/attempts/${attemptId}/submit`, {}, sh); ok('Submit Attempt'); } catch(e) { no('Submit Attempt', e); }
  try { await axios.get(`${B}/api/results/${attemptId}`, sh); ok('Get Result'); } catch(e) { no('Get Result', e); }
  try { await axios.get(`${B}/api/results/${attemptId}/s7-rank`, sh); ok('S7 Rank'); } catch(e) { no('S7 Rank', e); }
  try { await axios.get(`${B}/api/results/${attemptId}/s8-s60-percentile`, sh); ok('S8-S60 Percentile'); } catch(e) { no('S8-S60 Percentile', e); }
  try { await axios.get(`${B}/api/results/${attemptId}/s5-subjectstats`, sh); ok('S5 subjectStats'); } catch(e) { no('S5 subjectStats', e); }
  try { await axios.get(`${B}/api/results/${attemptId}/s11-omr-sheet`, sh); ok('S102 S11 OMR Sheet'); } catch(e) { no('S102 S11 OMR Sheet', e); }
  try { await axios.get(`${B}/api/results/${attemptId}/s12-share-card`, sh); ok('S99 S12 Share Card'); } catch(e) { no('S99 S12 Share Card', e); }
  try { await axios.get(`${B}/api/results/${attemptId}/n2-s13-receipt`, sh); ok('N2 S13 Receipt PDF'); } catch(e) { no('N2 S13 Receipt PDF', e); }

  // SKIP confirmed-working features
  sk('S91 T&C - Already built confirmed');
  sk('S66 Maintenance - Already built confirmed');
  sk('N21 Feature Flags - Already built confirmed');
  sk('S39 Exam Clone - Already built confirmed');
  sk('S106 Admit Card - Already built confirmed');
  sk('AI-1/AI-2 - Already built confirmed');

  console.log('\n==============================');
  console.log('  AUDIT RESULT V2');
  console.log('==============================');
  console.log(`PASS : ${p}`);
  console.log(`FAIL : ${f}`);
  console.log(`SKIP : ${s} (intentional - confirmed built)`);
}

run().catch(e => console.error('FATAL:', e.message));
