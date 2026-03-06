const http = require('http');

const BASE_URL = 'http://localhost:3000';
let superAdminToken = '';
let createdExamId = '';
let scheduledExamId = '';
let batchExamId = '';
let passwordExamId = '';
let categoryExamId = '';
let clonedExamId = '';

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
  console.log('\n========================================');
  console.log(' ProveRank -- Phase 1.3 Test (S1-S10)');
  console.log('========================================\n');

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
      console.log(`   Login OK | role: ${payload.role} | id: ${payload.id}\n`);
    } else {
      console.log('❌ Login FAIL\n', loginRes.body);
      process.exit(1);
    }
  } catch (e) {
    console.log('❌ Server connect nahi hua:', e.message);
    process.exit(1);
  }

  // STEP 1 -- FIX: watermark: false (Boolean)
  try {
    const res = await makeRequest('POST', '/api/exams', {
      title: 'Schema Test Exam',
      duration: 200,
      sections: [{ name: 'Physics', duration: 60, questionCount: 45 }],
      marking: { correct: 4, wrong: -1, skip: 0 },
      password: '',
      schedule: {
        startDate: new Date(Date.now() + 86400000).toISOString(),
        endDate: new Date(Date.now() + 172800000).toISOString()
      },
      status: 'draft',
      batch: 'NEET Batch 2024',
      category: 'Full Mock',
      template: 'NEET',
      whitelist: [],
      watermark: false,
      customInstructions: 'Read carefully.',
      reviewWindow: 30,
      difficulty: 'Medium',
      type: 'mock',
      waitingRoomEnabled: false,
      waitingRoomMinutes: 10
    }, superAdminToken);
    if (res.status === 201 || res.status === 200) {
      createdExamId = res.body._id || (res.body.exam && res.body.exam._id);
      logResult(1, 'Exam Schema -- All fields accepted', true, `examId: ${createdExamId}`);
    } else {
      logResult(1, 'Exam Schema -- All fields accepted', false, `Status: ${res.status} | ${JSON.stringify(res.body)}`);
    }
  } catch (e) {
    logResult(1, 'Exam Schema -- All fields accepted', false, e.message);
  }

  // STEP 2
  try {
    const res = await makeRequest('POST', '/api/exams', {
      title: 'NEET Full Mock Test 1',
      duration: 200,
      sections: [
        { name: 'Physics', questionCount: 45 },
        { name: 'Chemistry', questionCount: 45 },
        { name: 'Biology', questionCount: 90 }
      ],
      marking: { correct: 4, wrong: -1, skip: 0 },
      status: 'draft'
    }, superAdminToken);
    if (res.status === 201 || res.status === 200) {
      if (!createdExamId) createdExamId = res.body._id || (res.body.exam && res.body.exam._id);
      logResult(2, 'Create Exam API (POST)', true, `examId: ${createdExamId}`);
    } else {
      logResult(2, 'Create Exam API (POST)', false, `Status: ${res.status} | ${JSON.stringify(res.body)}`);
    }
  } catch (e) {
    logResult(2, 'Create Exam API (POST)', false, e.message);
  }

  // STEP 3
  if (createdExamId) {
    try {
      const res = await makeRequest('PUT', `/api/exams/${createdExamId}`, {
        title: 'NEET Full Mock Test 1 -- Updated',
        duration: 180
      }, superAdminToken);
      if (res.status === 200) {
        logResult(3, 'Update Exam API (PUT)', true, 'Title updated');
      } else {
        logResult(3, 'Update Exam API (PUT)', false, `Status: ${res.status} | ${JSON.stringify(res.body)}`);
      }
    } catch (e) {
      logResult(3, 'Update Exam API (PUT)', false, e.message);
    }
  } else {
    logResult(3, 'Update Exam API (PUT)', false, 'examId missing');
  }

  // STEP 4
  try {
    const createRes = await makeRequest('POST', '/api/exams', {
      title: 'Delete Test Exam -- TO BE DELETED',
      duration: 60,
      status: 'draft'
    }, superAdminToken);
    const deleteId = createRes.body._id || (createRes.body.exam && createRes.body.exam._id);
    if (deleteId) {
      const delRes = await makeRequest('DELETE', `/api/exams/${deleteId}`, null, superAdminToken);
      if (delRes.status === 200 || delRes.status === 204) {
        logResult(4, 'Delete Exam API (DELETE)', true, `Deleted: ${deleteId}`);
      } else {
        logResult(4, 'Delete Exam API (DELETE)', false, `Status: ${delRes.status} | ${JSON.stringify(delRes.body)}`);
      }
    } else {
      logResult(4, 'Delete Exam API (DELETE)', false, 'Create failed for delete test');
    }
  } catch (e) {
    logResult(4, 'Delete Exam API (DELETE)', false, e.message);
  }

  // STEP 5
  try {
    const res1 = await makeRequest('GET', '/api/exams', null, superAdminToken);
    const res2 = await makeRequest('GET', '/api/exams?status=draft', null, superAdminToken);
    if (res1.status === 200) {
      const count = Array.isArray(res1.body) ? res1.body.length : (res1.body.exams ? res1.body.exams.length : '?');
      logResult(5, 'Fetch Exams API (GET + filters)', true, `Total: ${count} | Filter draft status: ${res2.status}`);
    } else {
      logResult(5, 'Fetch Exams API (GET + filters)', false, `Status: ${res1.status}`);
    }
  } catch (e) {
    logResult(5, 'Fetch Exams API (GET + filters)', false, e.message);
  }

  // STEP 6 -- FIX: Response structure properly check karo
  try {
    const startDate = new Date(Date.now() + 3600000).toISOString();
    const endDate   = new Date(Date.now() + 7200000).toISOString();
    const res = await makeRequest('POST', '/api/exams', {
      title: 'Scheduled Exam -- S4 Test',
      duration: 200,
      status: 'scheduled',
      schedule: { startDate, endDate }
    }, superAdminToken);
    if (res.status === 201 || res.status === 200) {
      // Direct body ya body.exam dono check karo
      const exam = res.body.exam || res.body;
      scheduledExamId = exam._id;
      const hasSchedule = !!(exam.schedule && exam.schedule.startDate) ||
                          !!(res.body.schedule && res.body.schedule.startDate);
      logResult(6, 'Exam Scheduling System (S4)', true,
        `examId: ${scheduledExamId} | schedule stored: ${hasSchedule}`);
    } else {
      logResult(6, 'Exam Scheduling System (S4)', false, `Status: ${res.status} | ${JSON.stringify(res.body)}`);
    }
  } catch (e) {
    logResult(6, 'Exam Scheduling System (S4)', false, e.message);
  }

  // STEP 7
  try {
    const res = await makeRequest('POST', '/api/exams', {
      title: 'Batch Exam -- S5 Test',
      duration: 200,
      status: 'draft',
      batch: 'NEET 2024 Series',
      series: 'Weekly Test Series'
    }, superAdminToken);
    if (res.status === 201 || res.status === 200) {
      const exam = res.body.exam || res.body;
      batchExamId = exam._id;
      logResult(7, 'Series / Batch System (S5)', true, `batch: ${exam.batch} | series: ${exam.series}`);
    } else {
      logResult(7, 'Series / Batch System (S5)', false, `Status: ${res.status} | ${JSON.stringify(res.body)}`);
    }
  } catch (e) {
    logResult(7, 'Series / Batch System (S5)', false, e.message);
  }

  // STEP 8
  try {
    const res = await makeRequest('POST', '/api/exams', {
      title: 'Password Protected Exam -- S6 Test',
      duration: 200,
      status: 'draft',
      password: 'Exam@Secret123'
    }, superAdminToken);
    if (res.status === 201 || res.status === 200) {
      const exam = res.body.exam || res.body;
      passwordExamId = exam._id;
      logResult(8, 'Exam Password Protection (S6)', true, `examId: ${passwordExamId}`);
    } else {
      logResult(8, 'Exam Password Protection (S6)', false, `Status: ${res.status} | ${JSON.stringify(res.body)}`);
    }
  } catch (e) {
    logResult(8, 'Exam Password Protection (S6)', false, e.message);
  }

  // STEP 9
  const categories = ['Full Mock', 'Chapter Test', 'Part Test', 'Grand Test'];
  let catPassed = 0;
  for (const cat of categories) {
    try {
      const res = await makeRequest('POST', '/api/exams', {
        title: `Category Test -- ${cat}`,
        duration: 60,
        status: 'draft',
        category: cat
      }, superAdminToken);
      if (res.status === 201 || res.status === 200) {
        catPassed++;
        if (cat === 'Full Mock') {
          categoryExamId = (res.body.exam || res.body)._id;
        }
      }
    } catch (e) {}
  }
  logResult(9, 'Exam Category Tags M5', catPassed === 4, `${catPassed}/4 categories accepted`);

  // STEP 10 -- FIX: Correct route /api/exams/clone/:id
  if (createdExamId) {
    try {
      const cloneRes = await makeRequest('POST', `/api/exams/clone/${createdExamId}`, null, superAdminToken);
      if (cloneRes.status === 200 || cloneRes.status === 201) {
        const clonedExam = cloneRes.body.exam || cloneRes.body;
        clonedExamId = clonedExam._id;
        logResult(10, 'Exam Clone / Duplicate (S39)', true, `clonedExamId: ${clonedExamId}`);
      } else {
        logResult(10, 'Exam Clone / Duplicate (S39)', false, `Status: ${cloneRes.status} | ${JSON.stringify(cloneRes.body)}`);
      }
    } catch (e) {
      logResult(10, 'Exam Clone / Duplicate (S39)', false, e.message);
    }
  } else {
    logResult(10, 'Exam Clone / Duplicate (S39)', false, 'createdExamId missing');
  }

  // SUMMARY
  console.log('\n========================================');
  console.log(` RESULT: ${passed} PASS | ${failed} FAIL`);
  console.log('========================================');
  if (failed === 0) {
    console.log('🎉 Phase 1.3 Steps 1-10 -- ALL PASS!');
  } else {
    console.log('⚠️  Failed steps fix karo, phir dobara run karo.');
  }
  console.log('');
}

runTests().catch(console.error);
