const http = require('http');
let adminToken = '';
let questionId = '';

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
  console.log('\n====== PHASE 2.1 TEST START ======\n');

  // STEP 1 — Admin Login
  const login = await req('POST', '/api/auth/login', {
    email: 'admin@proverank.com',
    password: 'ProveRank@SuperAdmin123'
  });
  if (login.status === 200 && login.body.token) {
    adminToken = login.body.token;
    pass(1, `Admin login OK | role: ${login.body.role}`);
  } else { fail(1, 'Login FAIL', login.body); return; }

  // STEP 2 — Manual Add Question
  const addQ = await req('POST', '/api/questions', {
    text: 'Which organelle is known as the powerhouse of the cell?',
    hindiText: 'कौन सा अंगक कोशिका का पावरहाउस कहलाता है?',
    options: ['Nucleus', 'Mitochondria', 'Ribosome', 'Golgi Body'],
    correct: 1,
    subject: 'Biology',
    chapter: 'Cell Structure',
    topic: 'Organelles',
    difficulty: 'Easy',
    type: 'SCQ',
    explanation: 'Mitochondria produces ATP energy for the cell.',
    tags: ['biology', 'cell', 'NEET'],
    sourceExam: 'NEET 2020',
    approvalStatus: 'approved'
  }, adminToken);
  if (addQ.body?.question?._id) {
    questionId = addQ.body.question._id;
    pass(2, `Manual question add OK | id: ${questionId}`);
  } else { fail(2, 'Add question FAIL', addQ.body); }

  // STEP 3 — Fetch with Filters (S34)
  const fetchQ = await req('GET', '/api/questions?subject=Biology&difficulty=Easy', null, adminToken);
  if (fetchQ.status === 200) {
    const count = fetchQ.body?.questions?.length ?? fetchQ.body?.length ?? '?';
    pass(3, `Fetch questions OK | count: ${count}`);
  } else { fail(3, 'Fetch FAIL', fetchQ.body); }

  // STEP 4 — Edit Question (PUT)
  if (!questionId) { fail(4, 'SKIP — no questionId'); }
  else {
    const editQ = await req('PUT', `/api/questions/${questionId}`, {
      difficulty: 'Medium',
      topic: 'Cell Organelles Updated'
    }, adminToken);
    editQ.status === 200
      ? pass(4, `Edit question OK`)
      : fail(4, 'Edit FAIL', editQ.body);
  }

  // STEP 5 — Delete Question
  const tempQ = await req('POST', '/api/questions', {
    text: 'Temporary delete test question only',
    options: ['A', 'B', 'C', 'D'],
    correct: 0,
    subject: 'Physics', chapter: 'Test', difficulty: 'Easy', type: 'SCQ'
  }, adminToken);
  const delId = tempQ.body?.question?._id;
  if (delId) {
    const delQ = await req('DELETE', `/api/questions/${delId}`, null, adminToken);
    delQ.status === 200
      ? pass(5, 'Delete question OK')
      : fail(5, 'Delete FAIL', delQ.body);
  } else { fail(5, 'Delete — temp create FAIL', tempQ.body); }

  // STEP 6 — Difficulty Levels Hard (S16)
  const hardQ = await req('POST', '/api/questions', {
    text: 'A ray of light travels from glass to air — calculate critical angle.',
    options: ['30 deg', '42 deg', '45 deg', '60 deg'],
    correct: 1,
    subject: 'Physics', chapter: 'Optics', difficulty: 'Hard', type: 'SCQ'
  }, adminToken);
  hardQ.body?.question?._id
    ? pass(6, `Difficulty Hard OK | id: ${hardQ.body.question._id}`)
    : fail(6, 'Difficulty Hard FAIL', hardQ.body);

  // STEP 7 — AI-1: Auto Difficulty Tagger
  const ai1 = await req('POST', '/api/questions/ai/suggest-difficulty', {
    questionText: 'What is the function of mitochondria in a cell?'
  }, adminToken);
  ai1.status === 200 && ai1.body?.suggestedDifficulty
    ? pass(7, `AI-1 Difficulty Tagger OK | suggested: ${ai1.body.suggestedDifficulty}`)
    : fail(7, 'AI-1 FAIL', ai1.body);

  // STEP 8 — AI-2: Auto Subject/Chapter Classifier
  const ai2 = await req('POST', '/api/questions/ai/classify', {
    questionText: "Boyle's law states pressure is inversely proportional to volume."
  }, adminToken);
  ai2.status === 200 && ai2.body?.suggested
    ? pass(8, `AI-2 Classifier OK | subject: ${ai2.body.suggested?.subject} | chapter: ${ai2.body.suggested?.chapter}`)
    : fail(8, 'AI-2 FAIL', ai2.body);

  // STEP 9 — AI-5: Concept Similarity Detector
  const ai5 = await req('POST', '/api/questions/ai/similarity', {
    questionText: 'Which organelle is the powerhouse of the cell?',
    threshold: 70
  }, adminToken);
  ai5.status === 200
    ? pass(9, `AI-5 Similarity OK | ${JSON.stringify(ai5.body).substring(0,80)}`)
    : fail(9, 'AI-5 FAIL', ai5.body);

  // STEP 10 — Duplicate Detector (S18)
  const dup = await req('POST', '/api/questions/check-duplicate', {
    text: 'Which organelle is known as the powerhouse of the cell?'
  }, adminToken);
  dup.status === 200
    ? pass(10, `Duplicate Detector OK | isDuplicate: ${dup.body?.isDuplicate}`)
    : fail(10, 'Duplicate FAIL', dup.body);

  // STEP 11 — Image Based Questions (S33)
  const imgQ = await req('POST', '/api/questions', {
    text: 'Identify the organelle shown in the diagram below.',
    options: ['Nucleus', 'Mitochondria', 'Chloroplast', 'ER'],
    correct: 1,
    subject: 'Biology', chapter: 'Cell Structure',
    difficulty: 'Medium', type: 'SCQ',
    image: 'https://example.com/cell_diagram.png'
  }, adminToken);
  imgQ.body?.question?._id
    ? pass(11, `Image Based Question OK | id: ${imgQ.body.question._id}`)
    : fail(11, 'Image Question FAIL', imgQ.body);

  // STEP 12 — Question Tags & Search
  const tagS = await req('GET', '/api/questions?tags=NEET', null, adminToken);
  tagS.status === 200
    ? pass(12, `Tags & Search OK | count: ${tagS.body?.questions?.length ?? tagS.body?.length ?? '?'}`)
    : fail(12, 'Tags FAIL', tagS.body);

  console.log('\n====== PHASE 2.1 STEPS 1-12 COMPLETE ======\n');
}

run().catch(e => console.error('FATAL:', e));
