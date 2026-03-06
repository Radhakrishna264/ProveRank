const http = require('http');

let adminToken = '';
let questionId = '';

function req(method, path, body, token) {
  return new Promise((resolve) => {
    const data = body ? JSON.stringify(body) : null;
    const opts = {
      hostname: 'localhost', port: 3000,
      path, method,
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
function fail(n, msg, detail) { console.log(`❌ Step ${n}: ${msg}`, JSON.stringify(detail||'').substring(0,120)); }

async function run() {
  console.log('\n====== FIX TEST — FAILED STEPS ======\n');

  // Login
  const login = await req('POST', '/api/auth/login', {
    email: 'admin@proverank.com',
    password: 'ProveRank@SuperAdmin123'
  });
  adminToken = login.body.token;
  console.log('🔐 Login:', login.status === 200 ? 'OK' : 'FAIL');

  // Pehle schema check karo — ek question fetch karke correct field dekho
  const existing = await req('GET', '/api/questions?limit=1', null, adminToken);
  const sample = existing.body?.questions?.[0] || existing.body?.[0];
  if (sample) {
    console.log('🔍 Schema Check — correct field type:', typeof sample.correct, '| value:', JSON.stringify(sample.correct));
    console.log('🔍 Schema Check — type field:', sample.type);
    console.log('🔍 Schema Check — options sample:', JSON.stringify(sample.options?.[0]));
  }

  // STEP 2 FIX — correct as index number (0,1,2,3)
  console.log('\n--- Testing correct as NUMBER (index) ---');
  const addNum = await req('POST', '/api/questions', {
    text: 'Which organelle is known as the powerhouse of the cell? [FIX TEST]',
    options: ['Nucleus', 'Mitochondria', 'Ribosome', 'Golgi Body'],
    correct: 1,
    subject: 'Biology',
    chapter: 'Cell Structure',
    topic: 'Organelles',
    difficulty: 'Easy',
    type: 'SCQ',
    explanation: 'Mitochondria produces ATP.',
    tags: ['biology', 'NEET'],
    sourceExam: 'NEET 2020',
    approvalStatus: 'approved'
  }, adminToken);
  console.log('correct=1 (number):', addNum.status, addNum.body?.message || addNum.body?._id || JSON.stringify(addNum.body).substring(0,100));

  if (addNum.status === 201 || addNum.status === 200) {
    questionId = addNum.body._id || addNum.body.question?._id;
    pass(2, `Question add OK with correct=1 | id: ${questionId}`);
  } else {
    // Try correct as string index
    console.log('\n--- Testing correct as STRING "1" ---');
    const addStr = await req('POST', '/api/questions', {
      text: 'Powerhouse of cell test 2',
      options: ['A', 'B', 'C', 'D'],
      correct: '1',
      subject: 'Biology', chapter: 'Cell', difficulty: 'Easy', type: 'SCQ'
    }, adminToken);
    console.log('correct="1" (string):', addStr.status, JSON.stringify(addStr.body).substring(0,100));

    // Try correctAnswer field
    console.log('\n--- Testing correctAnswer field ---');
    const addCA = await req('POST', '/api/questions', {
      text: 'Powerhouse of cell test 3',
      options: ['A', 'B', 'C', 'D'],
      correctAnswer: 1,
      subject: 'Biology', chapter: 'Cell', difficulty: 'Easy', type: 'SCQ'
    }, adminToken);
    console.log('correctAnswer=1:', addCA.status, JSON.stringify(addCA.body).substring(0,100));

    // Try answer field
    console.log('\n--- Testing answer field ---');
    const addAns = await req('POST', '/api/questions', {
      text: 'Powerhouse of cell test 4',
      options: ['A', 'B', 'C', 'D'],
      answer: 1,
      subject: 'Biology', chapter: 'Cell', difficulty: 'Easy', type: 'SCQ'
    }, adminToken);
    console.log('answer=1:', addAns.status, JSON.stringify(addAns.body).substring(0,100));
  }

  // STEP 5 FIX — Delete test
  if (questionId) {
    const del = await req('DELETE', `/api/questions/${questionId}`, null, adminToken);
    console.log('\nStep 5 Delete test:', del.status === 200 ? '✅ PASS' : '❌ FAIL', del.body?.message || '');
  }

  // STEP 6 FIX — Hard difficulty
  const hardQ = await req('POST', '/api/questions', {
    text: 'Hard Physics question — refraction velocity test',
    options: ['1.5x10^8', '2x10^8', '3x10^8', '2.5x10^8'],
    correct: 2,
    subject: 'Physics', chapter: 'Optics', difficulty: 'Hard', type: 'SCQ'
  }, adminToken);
  console.log('\nStep 6 Hard Difficulty:', hardQ.status === 200 || hardQ.status === 201 ? '✅ PASS' : '❌ FAIL', hardQ.body?.message || hardQ.body?._id || '');

  // STEP 7 — AI-1 route check
  const ai1 = await req('POST', '/api/questions/ai/suggest-difficulty', { text: 'What is mitochondria?' }, adminToken);
  console.log('\nStep 7 AI-1:', ai1.status, JSON.stringify(ai1.body).substring(0,80));

  // STEP 8 — AI-2 route check  
  const ai2 = await req('POST', '/api/questions/ai/classify', { text: "Boyle's law relates pressure and volume" }, adminToken);
  console.log('Step 8 AI-2:', ai2.status, JSON.stringify(ai2.body).substring(0,80));

  // STEP 9 — AI-5 route check
  const ai5 = await req('POST', '/api/questions/ai/similarity', { text: 'powerhouse of cell' }, adminToken);
  console.log('Step 9 AI-5:', ai5.status, JSON.stringify(ai5.body).substring(0,80));

  // STEP 11 — Image question with correct=number
  const imgQ = await req('POST', '/api/questions', {
    text: 'Identify the organelle in the diagram.',
    options: ['Nucleus', 'Mitochondria', 'Chloroplast', 'ER'],
    correct: 1,
    subject: 'Biology', chapter: 'Cell Structure', difficulty: 'Medium',
    type: 'SCQ',
    image: 'https://example.com/cell_diagram.png'
  }, adminToken);
  console.log('\nStep 11 Image Question:', imgQ.status === 200 || imgQ.status === 201 ? '✅ PASS' : '❌ FAIL', imgQ.body?._id || imgQ.body?.message || '');

  console.log('\n====== FIX TEST COMPLETE ======\n');
  console.log('👆 Upar ka output dekho — correct field ka sahi format pata chalega');
}

run().catch(e => console.error('FATAL:', e));
