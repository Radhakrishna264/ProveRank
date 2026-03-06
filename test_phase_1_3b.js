const http = require('http');

let superAdminToken = '';
let examId = '';
let passed = 0;
let failed = 0;

function makeRequest(method, path, body, token) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
        ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {})
      }
    };
    const req = http.request(options, (res) => {
      let responseData = '';
      res.on('data', (chunk) => { responseData += chunk; });
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, body: JSON.parse(responseData) });
        } catch (e) {
          resolve({ status: res.statusCode, body: responseData });
        }
      });
    });
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

function logResult(stepNo, stepName, pass, detail) {
  if (pass) {
    console.log(`✅ Step ${stepNo} PASS -- ${stepName}`);
    if (detail) console.log(`   → ${detail}`);
    passed++;
  } else {
    console.log(`❌ Step ${stepNo} FAIL -- ${stepName}`);
    if (detail) console.log(`   → ${detail}`);
    failed++;
  }
}

async function runTests() {
  console.log('\n=========================================');
  console.log(' ProveRank -- Phase 1.3 Test (S11-S20)');
  console.log('=========================================\n');

  // LOGIN
  console.log('🔐 SuperAdmin Login...');
  try {
    const loginRes = await makeRequest('POST', '/api/auth/login', {
      email: 'admin@proverank.com',
      password: 'ProveRank@SuperAdmin123'
    });
    if (loginRes.status === 200 && loginRes.body.token) {
      superAdminToken = loginRes.body.token;
      const payload = JSON.parse(Buffer.from(superAdminToken.split('.')[1], 'base64').toString());
      console.log(`   Login OK | role: ${payload.role}\n`);
    } else {
      console.log('❌ Login FAIL\n', loginRes.body);
      process.exit(1);
    }
  } catch (e) {
    console.log('❌ Server connect nahi hua:', e.message);
    process.exit(1);
  }

  // Fresh exam banao -- sab steps ke liye
  console.log('📝 Test Exam Create kar raha hoon...');
  try {
    const res = await makeRequest('POST', '/api/exams', {
      title: 'Phase 1.3b Test Exam',
      duration: 200,
      status: 'draft',
      sections: [
        { name: 'Physics', questionCount: 45, duration: 60 },
        { name: 'Chemistry', questionCount: 45, duration: 60 },
        { name: 'Biology', questionCount: 90, duration: 80 }
      ],
      marking: { correct: 4, wrong: -1, skip: 0 },
      customInstructions: 'Default instructions',
      reviewWindow: 0,
      watermark: false
    }, superAdminToken);
    if (res.status === 201 || res.status === 200) {
      examId = (res.body.exam || res.body)._id;
      console.log(`   Exam created: ${examId}\n`);
    } else {
      console.log('❌ Exam create FAIL -- test abort\n', res.body);
      process.exit(1);
    }
  } catch (e) {
    console.log('❌ Exam create error:', e.message);
    process.exit(1);
  }

  // ================================================
  // STEP 11 -- Exam Template System S75
  // ================================================
  try {
    // Template save karo
    const saveRes = await makeRequest('PUT', `/api/exams/${examId}`, {
      template: 'NEET'
    }, superAdminToken);

    // Template fetch karo
    const getRes = await makeRequest('GET', `/api/exams/${examId}/template`, null, superAdminToken);

    // All templates list
    const listRes = await makeRequest('GET', '/api/exams/templates', null, superAdminToken);

    const templateOk = getRes.status === 200 || listRes.status === 200;
    logResult(11, 'Exam Template System (S75)', templateOk,
      `template GET: ${getRes.status} | templates list: ${listRes.status}`);
  } catch (e) {
    logResult(11, 'Exam Template System (S75)', false, e.message);
  }

  // ================================================
  // STEP 12 -- Exam Access Control Whitelist S85
  // ================================================
  try {
    // Student fetch karo whitelist ke liye
    const studentsRes = await makeRequest('GET', '/api/admin/manage/students', null, superAdminToken);
    let studentId = null;
    if (studentsRes.status === 200) {
      const students = studentsRes.body.students || studentsRes.body;
      if (Array.isArray(students) && students.length > 0) {
        studentId = students[0]._id;
      }
    }

    // Whitelist set karo
    const whitelistBody = studentId
      ? { studentIds: [studentId], enabled: true }
      : { studentIds: [], enabled: true };

    const postRes = await makeRequest('POST', `/api/exams/${examId}/whitelist`, whitelistBody, superAdminToken);
    const putRes  = await makeRequest('PUT',  `/api/exams/${examId}/whitelist`, whitelistBody, superAdminToken);

    const ok = postRes.status === 200 || postRes.status === 201 ||
               putRes.status  === 200 || putRes.status  === 201;
    logResult(12, 'Exam Access Control Whitelist (S85)', ok,
      `POST: ${postRes.status} | PUT: ${putRes.status} | studentId: ${studentId}`);
  } catch (e) {
    logResult(12, 'Exam Access Control Whitelist (S85)', false, e.message);
  }

  // ================================================
  // STEP 13 -- Section Wise Exam + Timer S26
  // ================================================
  try {
    const sectionsData = {
      sections: [
        { name: 'Physics',   questionCount: 45, duration: 60,  order: 1 },
        { name: 'Chemistry', questionCount: 45, duration: 60,  order: 2 },
        { name: 'Biology',   questionCount: 90, duration: 80,  order: 3 }
      ]
    };
    const putRes = await makeRequest('PUT', `/api/exams/${examId}/sections`, sectionsData, superAdminToken);
    const getRes = await makeRequest('GET', `/api/exams/${examId}/sections`, null, superAdminToken);

    const ok = putRes.status === 200 || getRes.status === 200;
    logResult(13, 'Section Wise Exam + Timer (S26)', ok,
      `PUT sections: ${putRes.status} | GET sections: ${getRes.status}`);
  } catch (e) {
    logResult(13, 'Section Wise Exam + Timer (S26)', false, e.message);
  }

  // ================================================
  // STEP 14 -- Custom Marking Scheme S62
  // ================================================
  try {
    const markingData = {
      correct: 4,
      wrong: -1,
      skip: 0
    };
    const res = await makeRequest('PUT', `/api/exams/${examId}/marking`, markingData, superAdminToken);
    logResult(14, 'Custom Marking Scheme (S62)', res.status === 200,
      `Status: ${res.status} | ${JSON.stringify(res.body).slice(0, 80)}`);
  } catch (e) {
    logResult(14, 'Custom Marking Scheme (S62)', false, e.message);
  }

  // ================================================
  // STEP 15 -- Custom Instructions per Exam
  // ================================================
  try {
    const res = await makeRequest('PUT', `/api/exams/${examId}`, {
      customInstructions: 'Yeh ek custom instruction hai. Mobile use band hai. Calculator allowed nahi.'
    }, superAdminToken);

    const exam = res.body.exam || res.body;
    const hasInstructions = !!(exam.customInstructions);
    logResult(15, 'Custom Instructions per Exam', res.status === 200 && hasInstructions,
      `Status: ${res.status} | customInstructions saved: ${hasInstructions}`);
  } catch (e) {
    logResult(15, 'Custom Instructions per Exam', false, e.message);
  }

  // ================================================
  // STEP 16 -- Exam Review Window Control
  // ================================================
  try {
    const res = await makeRequest('PUT', `/api/exams/${examId}`, {
      reviewWindow: 60
    }, superAdminToken);

    const exam = res.body.exam || res.body;
    const hasReviewWindow = exam.reviewWindow !== undefined;
    logResult(16, 'Exam Review Window Control', res.status === 200 && hasReviewWindow,
      `Status: ${res.status} | reviewWindow: ${exam.reviewWindow}`);
  } catch (e) {
    logResult(16, 'Exam Review Window Control', false, e.message);
  }

  // ================================================
  // STEP 17 -- Re-attempt System S31
  // ================================================
  try {
    const reattemptData = {
      reattemptEnabled: true,
      maxAttempts: 3,
      scoreType: 'best'
    };
    const res = await makeRequest('PUT', `/api/exams/${examId}/reattempt`, reattemptData, superAdminToken);
    logResult(17, 'Re-attempt System (S31)', res.status === 200,
      `Status: ${res.status} | ${JSON.stringify(res.body).slice(0, 80)}`);
  } catch (e) {
    logResult(17, 'Re-attempt System (S31)', false, e.message);
  }

  // ================================================
  // STEP 18 -- Exam Countdown Landing Page S96
  // ================================================
  try {
    // Pehle schedule set karo
    await makeRequest('PUT', `/api/exams/${examId}`, {
      status: 'scheduled',
      schedule: {
        startDate: new Date(Date.now() + 3600000).toISOString(),
        endDate:   new Date(Date.now() + 7200000).toISOString()
      }
    }, superAdminToken);

    const res = await makeRequest('GET', `/api/exams/${examId}/countdown`, null, superAdminToken);

    // countdown data check
    const body = res.body;
    const hasCountdown = res.status === 200 &&
      (body.timeRemaining !== undefined || body.countdown !== undefined ||
       body.startDate !== undefined || body.message !== undefined);

    logResult(18, 'Exam Countdown Landing Page (S96)', res.status === 200,
      `Status: ${res.status} | fields: ${Object.keys(body).join(', ')}`);
  } catch (e) {
    logResult(18, 'Exam Countdown Landing Page (S96)', false, e.message);
  }

  // ================================================
  // STEP 19 -- Maintenance Mode S66
  // ================================================
  try {
    // Maintenance ON karo
    const onRes = await makeRequest('POST', '/api/admin/maintenance', {
      enabled: true,
      message: 'Site update chal raha hai -- 30 minute mein wapas aayega'
    }, superAdminToken);

    // Status check
    const getRes = await makeRequest('GET', '/api/admin/maintenance', null, superAdminToken);

    // Maintenance OFF karo -- production safe rahega
    const offRes = await makeRequest('POST', '/api/admin/maintenance', {
      enabled: false,
      message: ''
    }, superAdminToken);

    const ok = (onRes.status === 200 || onRes.status === 201) &&
               (getRes.status === 200);
    logResult(19, 'Maintenance Mode (S66)', ok,
      `ON: ${onRes.status} | GET: ${getRes.status} | OFF: ${offRes.status}`);
  } catch (e) {
    logResult(19, 'Maintenance Mode (S66)', false, e.message);
  }

  // ================================================
  // STEP 20 -- Feature Flag System N21
  // ================================================
  try {
    // Current flags dekho
    const getRes = await makeRequest('GET', '/api/admin/feature-flags', null, superAdminToken);

    // Ek flag update karo
    const putRes = await makeRequest('PUT', '/api/admin/feature-flags', {
      feature: 'darkMode',
      enabled: true
    }, superAdminToken);

    const ok = getRes.status === 200 &&
               (putRes.status === 200 || putRes.status === 201);
    logResult(20, 'Feature Flag System N21', ok,
      `GET flags: ${getRes.status} | PUT flags: ${putRes.status} | flags: ${JSON.stringify(getRes.body).slice(0,80)}`);
  } catch (e) {
    logResult(20, 'Feature Flag System N21', false, e.message);
  }

  // ================================================
  // SUMMARY
  // ================================================
  console.log('\n=========================================');
  console.log(` RESULT: ${passed} PASS | ${failed} FAIL`);
  console.log('=========================================');
  if (failed === 0) {
    console.log('🎉 Phase 1.3 Steps 11-20 -- ALL PASS!');
    console.log('🏆 Phase 1.3 COMPLETE -- Git push ready!');
  } else {
    console.log('⚠️  Failed steps fix karo, phir dobara run karo.');
  }
  console.log('');
}

runTests().catch(console.error);
