const http = require('http');
let adminToken = '', studentToken = '', questionId = '';

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
function fail(n, msg, d) { console.log(`❌ Step ${n}: ${msg}`, JSON.stringify(d||'').substring(0,100)); }

async function run() {
  console.log('\n====== PHASE 2.1 FINAL TEST — ALL 22 STEPS ======\n');

  // STEP 1 — Admin Login
  const login = await req('POST', '/api/auth/login', {
    email: 'admin@proverank.com', password: 'ProveRank@SuperAdmin123'
  });
  if (login.status === 200 && login.body.token) {
    adminToken = login.body.token;
    pass(1, `Admin login OK | role: ${login.body.role}`);
  } else { fail(1, 'Login FAIL', login.body); return; }

  // Student Login
  const sl = await req('POST', '/api/auth/login', {
    email: 'student@proverank.com', password: 'ProveRank@123'
  });
  studentToken = sl.body?.token || adminToken;

  // STEP 2 — Manual Add Question
  const addQ = await req('POST', '/api/questions', {
    text: 'Which organelle is known as the powerhouse of the cell?',
    hindiText: 'कौन सा अंगक कोशिका का पावरहाउस कहलाता है?',
    options: ['Nucleus', 'Mitochondria', 'Ribosome', 'Golgi Body'],
    correct: 1, subject: 'Biology', chapter: 'Cell Structure',
    topic: 'Organelles', difficulty: 'Easy', type: 'SCQ',
    explanation: 'Mitochondria produces ATP.', tags: ['biology','NEET'],
    sourceExam: 'NEET 2020', approvalStatus: 'approved'
  }, adminToken);
  if (addQ.body?.question?._id) {
    questionId = addQ.body.question._id;
    pass(2, `Add question OK | id: ${questionId}`);
  } else { fail(2, 'Add FAIL', addQ.body); }

  // STEP 3 — Fetch with Filters (S34)
  const fq = await req('GET', '/api/questions?subject=Biology&difficulty=Easy', null, adminToken);
  fq.status === 200
    ? pass(3, `Fetch questions OK | count: ${fq.body?.questions?.length ?? fq.body?.length ?? '?'}`)
    : fail(3, 'Fetch FAIL', fq.body);

  // STEP 4 — Edit Question
  if (questionId) {
    const eq = await req('PUT', `/api/questions/${questionId}`, { difficulty: 'Medium' }, adminToken);
    eq.status === 200 ? pass(4, 'Edit OK') : fail(4, 'Edit FAIL', eq.body);
  } else fail(4, 'SKIP');

  // STEP 5 — Delete Question
  const tq = await req('POST', '/api/questions', {
    text: 'Temp delete test', options: ['A','B','C','D'], correct: 0,
    subject: 'Physics', chapter: 'Test', difficulty: 'Easy', type: 'SCQ'
  }, adminToken);
  const delId = tq.body?.question?._id;
  if (delId) {
    const dq = await req('DELETE', `/api/questions/${delId}`, null, adminToken);
    dq.status === 200 ? pass(5, 'Delete OK') : fail(5, 'Delete FAIL', dq.body);
  } else fail(5, 'Delete SKIP', tq.body);

  // STEP 6 — Difficulty Levels (S16)
  const hq = await req('POST', '/api/questions', {
    text: 'Hard Physics — critical angle calculation',
    options: ['30','42','45','60'], correct: 1,
    subject: 'Physics', chapter: 'Optics', difficulty: 'Hard', type: 'SCQ'
  }, adminToken);
  hq.body?.question?._id
    ? pass(6, `Difficulty Hard OK | id: ${hq.body.question._id}`)
    : fail(6, 'Difficulty FAIL', hq.body);

  // STEP 7 — AI-1: Auto Difficulty Tagger
  const ai1 = await req('POST', '/api/questions/ai/suggest-difficulty', {
    questionText: 'What is the function of mitochondria?'
  }, adminToken);
  ai1.status === 200 && ai1.body?.suggestedDifficulty
    ? pass(7, `AI-1 OK | suggested: ${ai1.body.suggestedDifficulty}`)
    : fail(7, 'AI-1 FAIL', ai1.body);

  // STEP 8 — AI-2: Classifier
  const ai2 = await req('POST', '/api/questions/ai/classify', {
    questionText: "Boyle's law — pressure inversely proportional to volume"
  }, adminToken);
  ai2.status === 200
    ? pass(8, `AI-2 OK | subject: ${ai2.body?.suggested?.subject}`)
    : fail(8, 'AI-2 FAIL', ai2.body);

  // STEP 9 — AI-5: Similarity
  const ai5 = await req('POST', '/api/questions/ai/similarity', {
    questionText: 'Which organelle is powerhouse of cell?', threshold: 70
  }, adminToken);
  ai5.status === 200
    ? pass(9, `AI-5 OK | ${JSON.stringify(ai5.body).substring(0,60)}`)
    : fail(9, 'AI-5 FAIL', ai5.body);

  // STEP 10 — Duplicate Detector (S18)
  const dup = await req('POST', '/api/questions/check-duplicate', {
    text: 'Which organelle is known as the powerhouse of the cell?'
  }, adminToken);
  dup.status === 200
    ? pass(10, `Duplicate Detector OK | isDuplicate: ${dup.body?.isDuplicate}`)
    : fail(10, 'Duplicate FAIL', dup.body);

  // STEP 11 — Image Based (S33)
  const iq = await req('POST', '/api/questions', {
    text: 'Identify organelle in diagram.',
    options: ['Nucleus','Mitochondria','Chloroplast','ER'], correct: 1,
    subject: 'Biology', chapter: 'Cell Structure', difficulty: 'Medium',
    type: 'SCQ', image: 'https://example.com/cell.png'
  }, adminToken);
  iq.body?.question?._id
    ? pass(11, `Image Question OK | id: ${iq.body.question._id}`)
    : fail(11, 'Image FAIL', iq.body);

  // STEP 12 — Tags & Search
  const ts = await req('GET', '/api/questions?tags=NEET', null, adminToken);
  ts.status === 200
    ? pass(12, `Tags & Search OK | count: ${ts.body?.questions?.length ?? ts.body?.length ?? '?'}`)
    : fail(12, 'Tags FAIL', ts.body);

  // STEP 13 — Usage Tracker (S35)
  if (questionId) {
    const uq = await req('GET', `/api/questions/${questionId}`, null, adminToken);
    const uc = uq.body?.usageCount ?? uq.body?.question?.usageCount ?? 0;
    uq.status === 200
      ? pass(13, `Usage Tracker OK | usageCount: ${uc}`)
      : fail(13, 'Usage FAIL', uq.body);
  } else fail(13, 'SKIP');

  // STEP 14 — Version History (S87)
  if (questionId) {
    const vq = await req('GET', `/api/questions/${questionId}/versions`, null, adminToken);
    vq.status === 200
      ? pass(14, `Version History OK | versions: ${vq.body?.versions?.length ?? 0}`)
      : fail(14, 'Version FAIL', vq.body);
  } else fail(14, 'SKIP');

  // STEP 15 — MSQ (S90)
  const mq = await req('POST', '/api/questions', {
    text: 'Which are correct about mitochondria? (Select all)',
    options: ['Double membrane','Own DNA','Found in prokaryotes','Produces ATP'],
    correct: [0,1,3], subject: 'Biology', chapter: 'Cell Structure',
    difficulty: 'Hard', type: 'MSQ'
  }, adminToken);
  mq.body?.question?._id
    ? pass(15, `MSQ OK | id: ${mq.body.question._id}`)
    : fail(15, 'MSQ FAIL', mq.body);

  // STEP 16 — Integer Type
  const intq = await req('POST', '/api/questions', {
    text: 'How many chambers in human heart?',
    options: ['Enter number','NA','NA','NA'], correct: 4,
    subject: 'Biology', chapter: 'Human Physiology', difficulty: 'Easy', type: 'Integer'
  }, adminToken);
  intq.body?.question?._id
    ? pass(16, `Integer Type OK | id: ${intq.body.question._id}`)
    : fail(16, 'Integer FAIL', intq.body);

  // STEP 17 — PYQ Bank (S104)
  const pq = await req('POST', '/api/questions', {
    text: 'NEET 2020 — Which gas released in photosynthesis?',
    options: ['CO2','O2','N2','H2'], correct: 1,
    subject: 'Biology', chapter: 'Photosynthesis', difficulty: 'Easy',
    type: 'SCQ', sourceExam: 'NEET 2020', tags: ['PYQ','NEET2020']
  }, adminToken);
  pq.body?.question?._id
    ? pass(17, `PYQ Bank OK | id: ${pq.body.question._id}`)
    : fail(17, 'PYQ FAIL', pq.body);

  // STEP 18 — Error Reporting (S84)
  if (questionId) {
    const rq = await req('POST', `/api/questions/${questionId}/report`, {
      reason: 'Wrong answer key in this question'
    }, studentToken);
    rq.status === 200 || rq.status === 201
      ? pass(18, `Error Reporting OK`)
      : fail(18, 'Report FAIL', rq.body);
  } else fail(18, 'SKIP');

  // STEP 19 — AI-8: Translator
  const ai8 = await req('POST', '/api/questions/ai/translate', {
    questionText: 'Which organelle is the powerhouse of the cell?',
    targetLanguage: 'hindi'
  }, adminToken);
  ai8.status === 200
    ? pass(19, `AI-8 Translator OK`)
    : fail(19, 'AI-8 FAIL', ai8.body);

  // STEP 20 — AI-10: Explanation
  const ai10 = await req('POST', '/api/questions/ai/explanation', {
    questionText: 'Which organelle is the powerhouse of the cell?',
    correctAnswer: 'Mitochondria'
  }, adminToken);
  ai10.status === 200
    ? pass(20, `AI-10 Explanation OK`)
    : fail(20, 'AI-10 FAIL', ai10.body);

  // STEP 21 — Approval Workflow (N7)
  const aq = await req('POST', '/api/questions', {
    text: 'Approval workflow test question',
    options: ['A','B','C','D'], correct: 0,
    subject: 'Physics', chapter: 'Test', difficulty: 'Easy',
    type: 'SCQ', approvalStatus: 'pending'
  }, adminToken);
  const apId = aq.body?.question?._id;
  if (apId) {
    const apr = await req('PUT', `/api/questions/${apId}/approve`, {
      approvalStatus: 'approved'
    }, adminToken);
    apr.status === 200
      ? pass(21, `Approval Workflow OK`)
      : fail(21, 'Approval FAIL', apr.body);
  } else fail(21, 'Approval create FAIL', aq.body);

  // STEP 22 — XML/Moodle Import (M11)
  const xmlStr = '<?xml version="1.0"?><quiz><question type="multichoice"><questiontext><text>What is H2O?</text></questiontext></question></quiz>';
  const xq = await req('POST', '/api/questions/import/xml', {
    xmlData: xmlStr
  }, adminToken);
  xq.status === 200 || xq.status === 201
    ? pass(22, `XML Import OK | ${JSON.stringify(xq.body).substring(0,60)}`)
    : fail(22, 'XML FAIL', xq.body);

  console.log('\n====== PHASE 2.1 FINAL TEST COMPLETE — ALL 22 STEPS ======\n');
}

run().catch(e => console.error('FATAL:', e));
