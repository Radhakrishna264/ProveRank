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
  console.log('\n====== FIX STEPS 14, 16, 17-20, 22 ======\n');

  // Login
  const login = await req('POST', '/api/auth/login', {
    email: 'admin@proverank.com', password: 'ProveRank@SuperAdmin123'
  });
  adminToken = login.body.token;

  const sLogin = await req('POST', '/api/auth/login', {
    email: 'student@proverank.com', password: 'ProveRank@123'
  });
  studentToken = sLogin.body?.token || adminToken;

  // Base question
  const addQ = await req('POST', '/api/questions', {
    text: 'Fix test base question — mitochondria ATP',
    options: ['Nucleus', 'Mitochondria', 'Ribosome', 'Golgi'],
    correct: 1,
    subject: 'Biology', chapter: 'Cell Structure',
    difficulty: 'Easy', type: 'SCQ'
  }, adminToken);
  questionId = addQ.body?.question?._id;
  console.log('Base question:', questionId || 'FAIL');

  // STEP 14 — Version History — route variations check
  await req('PUT', `/api/questions/${questionId}`, {
    text: 'Edited for version test', difficulty: 'Medium'
  }, adminToken);

  const v1 = await req('GET', `/api/questions/${questionId}/versions`, null, adminToken);
  const v2 = await req('GET', `/api/questions/${questionId}/history`, null, adminToken);
  const v3 = await req('GET', `/api/questions/${questionId}/version-history`, null, adminToken);

  console.log('v1 /versions:', v1.status);
  console.log('v2 /history:', v2.status);
  console.log('v3 /version-history:', v3.status);

  if (v1.status === 200) pass(14, `Version History OK via /versions`);
  else if (v2.status === 200) pass(14, `Version History OK via /history`);
  else if (v3.status === 200) pass(14, `Version History OK via /version-history`);
  else fail(14, 'Version History — check routes below', {v1: v1.body, v2: v2.body});

  // STEP 16 — Integer Type — options with placeholder
  const intQ = await req('POST', '/api/questions', {
    text: 'How many chambers does the human heart have?',
    options: ['Enter number', 'NA', 'NA', 'NA'],
    correct: 4,
    subject: 'Biology', chapter: 'Human Physiology',
    difficulty: 'Easy', type: 'Integer',
    explanation: 'Human heart has 4 chambers.'
  }, adminToken);

  if (intQ.body?.question?._id) {
    pass(16, `Integer Type OK | id: ${intQ.body.question._id}`);
  } else {
    // Try correct as string
    const intQ2 = await req('POST', '/api/questions', {
      text: 'How many bones in adult human body?',
      options: ['Enter number', 'NA', 'NA', 'NA'],
      correct: 206,
      subject: 'Biology', chapter: 'Human Physiology',
      difficulty: 'Medium', type: 'Integer'
    }, adminToken);
    intQ2.body?.question?._id
      ? pass(16, `Integer Type OK | id: ${intQ2.body.question._id}`)
      : fail(16, 'Integer Type FAIL', intQ2.body);
  }

  // STEP 17 — PYQ Bank
  const pyq = await req('POST', '/api/questions', {
    text: 'NEET 2020 PYQ — Which gas released during photosynthesis?',
    options: ['CO2', 'O2', 'N2', 'H2'], correct: 1,
    subject: 'Biology', chapter: 'Photosynthesis',
    difficulty: 'Easy', type: 'SCQ',
    sourceExam: 'NEET 2020', tags: ['PYQ', 'NEET2020']
  }, adminToken);
  pyq.body?.question?._id
    ? pass(17, `PYQ Bank OK | id: ${pyq.body.question._id}`)
    : fail(17, 'PYQ FAIL', pyq.body);

  // STEP 18 — Error Reporting (S84)
  const report = await req('POST', `/api/questions/${questionId}/report`, {
    reason: 'Wrong answer key in this question',
    reportedBy: 'student@proverank.com'
  }, studentToken);
  report.status === 200 || report.status === 201
    ? pass(18, `Error Reporting OK`)
    : fail(18, 'Error Reporting FAIL', report.body);

  // STEP 19 — AI-8 Translator
  const ai8 = await req('POST', '/api/questions/ai/translate', {
    questionText: 'Which organelle is the powerhouse of the cell?',
    targetLanguage: 'hindi'
  }, adminToken);
  ai8.status === 200
    ? pass(19, `AI-8 Translator OK | ${JSON.stringify(ai8.body).substring(0,80)}`)
    : fail(19, 'AI-8 FAIL', ai8.body);

  // STEP 20 — AI-10 Explanation
  const ai10 = await req('POST', '/api/questions/ai/explanation', {
    questionText: 'Which organelle is the powerhouse of the cell?',
    correctAnswer: 'Mitochondria'
  }, adminToken);
  ai10.status === 200
    ? pass(20, `AI-10 Explanation OK | ${JSON.stringify(ai10.body).substring(0,80)}`)
    : fail(20, 'AI-10 FAIL', ai10.body);

  // STEP 22 — XML Import — safe string (no angle brackets in JSON)
  const xmlStr = '<?xml version="1.0"?><quiz><question type="multichoice"><questiontext><text>What is H2O?</text></questiontext></question></quiz>';
  const xml22 = await req('POST', '/api/questions/import/xml', {
    xmlContent: xmlStr
  }, adminToken);
  xml22.status === 200 || xml22.status === 201
    ? pass(22, `XML Import OK | ${JSON.stringify(xml22.body).substring(0,80)}`)
    : fail(22, 'XML Import FAIL', xml22.body);

  console.log('\n====== FIX STEPS COMPLETE ======\n');
}

run().catch(e => console.error('FATAL:', e));
