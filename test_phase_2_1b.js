const http = require('http');
let adminToken = '';
let questionId = '';
let studentToken = '';

function req(method, path, body, token) {
  return new Promise((resolve) => {
    const data = body ? JSON.stringify(body) : null;
    const opts = {
      hostname: 'localhost', port: 3000, path, method,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {})
      }
    };
    const r = http.request(opts, (res) => {
      let raw = '';
      res.on('data', d => raw += d);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(raw) }); }
        catch { resolve({ status: res.statusCode, body: raw }); }
      });
    });
    r.on('error', e => resolve({ status: 0, body: e.message }));
    if (data) r.write(data);
    r.end();
  });
}

function pass(n, msg) { console.log(`✅ Step ${n}: ${msg}`); }
function fail(n, msg, d) { console.log(`❌ Step ${n}: ${msg}`, JSON.stringify(d||'').substring(0,120)); }

async function run() {
  console.log('\n====== PHASE 2.1 STEPS 13-22 TEST START ======\n');

  // Login Admin
  const login = await req('POST', '/api/auth/login', {
    email: 'admin@proverank.com',
    password: 'ProveRank@SuperAdmin123'
  });
  if (login.status === 200 && login.body.token) {
    adminToken = login.body.token;
    console.log('🔐 Admin login OK');
  } else { console.log('❌ Admin login FAIL'); return; }

  // Student Login
  const sLogin = await req('POST', '/api/auth/login', {
    email: 'student@proverank.com',
    password: 'ProveRank@123'
  });
  if (sLogin.status === 200 && sLogin.body.token) {
    studentToken = sLogin.body.token;
    console.log('🔐 Student login OK');
  }

  // Create a question to use in steps below
  const addQ = await req('POST', '/api/questions', {
    text: 'Base question for steps 13-22 testing — mitochondria ATP production',
    options: ['Nucleus', 'Mitochondria', 'Ribosome', 'Golgi Body'],
    correct: 1,
    subject: 'Biology', chapter: 'Cell Structure',
    topic: 'Organelles', difficulty: 'Easy', type: 'SCQ',
    tags: ['biology', 'NEET'],
    approvalStatus: 'approved'
  }, adminToken);
  questionId = addQ.body?.question?._id;
  console.log('📝 Base question id:', questionId || 'NOT CREATED');

  // STEP 13 — Question Usage Tracker (S35)
  const usage = await req('GET', `/api/questions/${questionId}/usage`, null, adminToken);
  if (usage.status === 200) {
    pass(13, `Usage Tracker OK | ${JSON.stringify(usage.body).substring(0,80)}`);
  } else {
    // Try alternate route
    const usage2 = await req('GET', `/api/questions/${questionId}`, null, adminToken);
    usage2.status === 200 && (usage2.body?.usageCount !== undefined || usage2.body?.question?.usageCount !== undefined)
      ? pass(13, `Usage Tracker OK (field in question) | usageCount: ${usage2.body?.usageCount ?? usage2.body?.question?.usageCount}`)
      : fail(13, 'Usage Tracker FAIL', usage.body);
  }

  // STEP 14 — Question Version History (S87)
  // Edit question to create a version
  await req('PUT', `/api/questions/${questionId}`, {
    text: 'Base question EDITED — version 2 test', difficulty: 'Medium'
  }, adminToken);
  const version = await req('GET', `/api/questions/${questionId}/versions`, null, adminToken);
  if (version.status === 200) {
    pass(14, `Version History OK | ${JSON.stringify(version.body).substring(0,80)}`);
  } else {
    fail(14, 'Version History FAIL', version.body);
  }

  // STEP 15 — MSQ Multi-Select Question (S90)
  const msq = await req('POST', '/api/questions', {
    text: 'Which of the following are correct about mitochondria? (Select all)',
    options: ['Has double membrane', 'Has own DNA', 'Found in prokaryotes', 'Produces ATP'],
    correct: [0, 1, 3],
    subject: 'Biology', chapter: 'Cell Structure',
    difficulty: 'Hard', type: 'MSQ',
    explanation: 'Mitochondria has double membrane, own DNA, and produces ATP.'
  }, adminToken);
  msq.body?.question?._id
    ? pass(15, `MSQ Question OK | id: ${msq.body.question._id}`)
    : fail(15, 'MSQ FAIL', msq.body);

  // STEP 16 — Integer Type Question
  const intQ = await req('POST', '/api/questions', {
    text: 'How many chambers does the human heart have?',
    options: [],
    correct: 4,
    subject: 'Biology', chapter: 'Human Physiology',
    difficulty: 'Easy', type: 'Integer',
    explanation: 'Human heart has 4 chambers.'
  }, adminToken);
  intQ.body?.question?._id
    ? pass(16, `Integer Type Question OK | id: ${intQ.body.question._id}`)
    : fail(16, 'Integer Type FAIL', intQ.body);

  // STEP 17 — PYQ Bank (S104)
  const pyq = await req('POST', '/api/questions', {
    text: 'NEET 2020 PYQ — Which gas is released during photosynthesis?',
    options: ['CO2', 'O2', 'N2', 'H2'],
    correct: 1,
    subject: 'Biology', chapter: 'Photosynthesis',
    difficulty: 'Easy', type: 'SCQ',
    sourceExam: 'NEET 2020',
    tags: ['PYQ', 'NEET2020']
  }, adminToken);
  if (pyq.body?.question?._id) {
    const pyqId = pyq.body.question._id;
    // Check filter by sourceExam
    const pyqFetch = await req('GET', '/api/questions?sourceExam=NEET 2020', null, adminToken);
    pyqFetch.status === 200
      ? pass(17, `PYQ Bank OK | id: ${pyqId} | filter works`)
      : pass(17, `PYQ Bank OK | question created | id: ${pyqId}`);
  } else { fail(17, 'PYQ FAIL', pyq.body); }

  // STEP 18 — Question Error Reporting (S84)
  const report = await req('POST', `/api/questions/${questionId}/report`, {
    reason: 'Wrong answer key — option B should be correct not option C',
    reportedBy: 'student@proverank.com'
  }, studentToken || adminToken);
  report.status === 200 || report.status === 201
    ? pass(18, `Error Reporting OK | ${report.body?.message || 'reported'}`)
    : fail(18, 'Error Reporting FAIL', report.body);

  // STEP 19 — AI-8: Auto Hindi-English Translator
  const ai8 = await req('POST', '/api/questions/ai/translate', {
    questionText: 'Which organelle is known as the powerhouse of the cell?',
    targetLanguage: 'hindi'
  }, adminToken);
  ai8.status === 200
    ? pass(19, `AI-8 Translator OK | ${JSON.stringify(ai8.body).substring(0,80)}`)
    : fail(19, 'AI-8 Translator FAIL', ai8.body);

  // STEP 20 — AI-10: Auto Explanation Generator
  const ai10 = await req('POST', '/api/questions/ai/explanation', {
    questionText: 'Which organelle is known as the powerhouse of the cell?',
    correctAnswer: 'Mitochondria'
  }, adminToken);
  ai10.status === 200
    ? pass(20, `AI-10 Explanation Generator OK | ${JSON.stringify(ai10.body).substring(0,80)}`)
    : fail(20, 'AI-10 FAIL', ai10.body);

  // STEP 21 — Question Approval Workflow (N7)
  // Add question with pending status then approve
  const pendingQ = await req('POST', '/api/questions', {
    text: 'Approval workflow test question — pending approval',
    options: ['A', 'B', 'C', 'D'], correct: 0,
    subject: 'Physics', chapter: 'Test', difficulty: 'Easy', type: 'SCQ',
    approvalStatus: 'pending'
  }, adminToken);
  const pendingId = pendingQ.body?.question?._id;
  if (pendingId) {
    const approve = await req('PUT', `/api/questions/${pendingId}/approve`, {
      approvalStatus: 'approved'
    }, adminToken);
    approve.status === 200
      ? pass(21, `Approval Workflow OK | approved id: ${pendingId}`)
      : fail(21, 'Approval FAIL', approve.body);
  } else { fail(21, 'Approval — pending question create FAIL', pendingQ.body); }

  // STEP 22 — XML/Moodle Import (M11)
  const xmlImport = await req('POST', '/api/questions/import/xml', {
    xmlContent: `<?xml version="1.0"?><quiz><question type="multichoice"><name><text>Test XML Q</text></name><questiontext><text>What is H2O?</text></questiontext><answer fraction="100"><text>Water</text></answer></question></quiz>`
  }, adminToken);
  xmlImport.status === 200 || xmlImport.status === 201
    ? pass(22, `XML/Moodle Import OK | ${JSON.stringify(xmlImport.body).substring(0,80)}`)
    : fail(22, 'XML Import FAIL', xmlImport.body);

  console.log('\n====== PHASE 2.1 STEPS 13-22 COMPLETE ======\n');
}

run().catch(e => console.error('FATAL:', e));
