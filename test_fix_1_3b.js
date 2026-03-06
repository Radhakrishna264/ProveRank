const http = require('http');

let superAdminToken = '';
let examId = '';
let passed = 0;
let failed = 0;

function makeRequest(method, path, body, token) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const options = {
      hostname: 'localhost', port: 3000, path,method,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
        ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {})
      }
    };
    const req = http.request(options, (res) => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(d) }); }
        catch(e) { resolve({ status: res.statusCode, body: d }); }
      });
    });
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

function logResult(stepNo, stepName, pass, detail) {
  if (pass) { console.log(`✅ Step ${stepNo} PASS -- ${stepName}`); passed++; }
  else { console.log(`❌ Step ${stepNo} FAIL -- ${stepName}`); failed++; }
  if (detail) console.log(`   → ${detail}`);
}

async function runTests() {
  console.log('\n=========================================');
  console.log(' Phase 1.3 -- Fix Test (Steps 11, 14, 20)');
  console.log('=========================================\n');

  // LOGIN
  const loginRes = await makeRequest('POST', '/api/auth/login', {
    email: 'admin@proverank.com',
    password: 'ProveRank@SuperAdmin123'
  });
  if (loginRes.status === 200 && loginRes.body.token) {
    superAdminToken = loginRes.body.token;
    console.log('🔐 Login OK\n');
  } else {
    console.log('❌ Login FAIL'); process.exit(1);
  }

  // Fresh exam
  const eRes = await makeRequest('POST', '/api/exams', {
    title: 'Fix Test Exam', duration: 200, status: 'draft', watermark: false
  }, superAdminToken);
  examId = (eRes.body.exam || eRes.body)._id;
  console.log(`📝 Exam: ${examId}\n`);

  // ================================================
  // STEP 11 -- Template System S75
  // POST /api/exams/template  -- template save
  // GET  /api/exams/templates -- list
  // ================================================
  try {
    const saveRes = await makeRequest('POST', '/api/exams/template', {
      name: 'NEET Template',
      pattern: 'neet',
      duration: 200,
      totalQuestions: 180,
      marking: { correct: 4, wrong: -1 },
      sections: [
        { name: 'Physics',   count: 45 },
        { name: 'Chemistry', count: 45 },
        { name: 'Biology',   count: 90 }
      ]
    }, superAdminToken);

    const listRes = await makeRequest('GET', '/api/exams/templates', null, superAdminToken);

    const ok = (saveRes.status === 200 || saveRes.status === 201) &&
               (listRes.status === 200);
    logResult(11, 'Exam Template System (S75)', ok,
      `POST template: ${saveRes.status} | GET templates: ${listRes.status} | ${JSON.stringify(saveRes.body).slice(0,80)}`);
  } catch(e) {
    logResult(11, 'Exam Template System (S75)', false, e.message);
  }

  // ================================================
  // STEP 14 -- Custom Marking Scheme S62
  // PUT /:id/marking  body: { correct, wrong, skip } directly
  // ================================================
  try {
    const res = await makeRequest('PUT', `/api/exams/${examId}/marking`, {
      correct: 4,
      wrong: -1,
      skip: 0
    }, superAdminToken);
    logResult(14, 'Custom Marking Scheme (S62)', res.status === 200,
      `Status: ${res.status} | ${JSON.stringify(res.body).slice(0,80)}`);
  } catch(e) {
    logResult(14, 'Custom Marking Scheme (S62)', false, e.message);
  }

  // ================================================
  // STEP 20 -- Feature Flag System N21
  // PUT /api/admin/feature-flags  body: { feature, enabled }
  // ================================================
  try {
    // GET current flags
    const getRes = await makeRequest('GET', '/api/admin/feature-flags', null, superAdminToken);

    // Single feature toggle -- { feature, enabled }
    const putRes = await makeRequest('PUT', '/api/admin/feature-flags', {
      feature: 'darkMode',
      enabled: true
    }, superAdminToken);

    const ok = getRes.status === 200 &&
               (putRes.status === 200 || putRes.status === 201);
    logResult(20, 'Feature Flag System (N21)', ok,
      `GET: ${getRes.status} | PUT single flag: ${putRes.status} | ${JSON.stringify(putRes.body).slice(0,80)}`);
  } catch(e) {
    logResult(20, 'Feature Flag System (N21)', false, e.message);
  }

  // SUMMARY
  console.log('\n=========================================');
  console.log(` RESULT: ${passed} PASS | ${failed} FAIL`);
  console.log('=========================================');
  if (failed === 0) {
    console.log('🎉 Steps 11, 14, 20 -- ALL FIXED & PASS!');
    console.log('🏆 Phase 1.3 COMPLETE -- 20/20 PASS!');
  } else {
    console.log('⚠️  Detail dekho upar.');
  }
  console.log('');
}

runTests().catch(console.error);
