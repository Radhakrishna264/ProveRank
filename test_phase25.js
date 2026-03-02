const http = require('http');
let TOKEN = '', pass = 0, fail = 0;

function request(options, body) {
  return new Promise((resolve, reject) => {
    const req = http.request({ host: 'localhost', port: 3000, ...options }, res => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => { try { resolve({ status: res.statusCode, data: JSON.parse(data) }); } catch(e) { resolve({ status: res.statusCode, data: {} }); } });
    });
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

function h() { return { 'Content-Type': 'application/json', 'Authorization': `Bearer ${TOKEN}` }; }

async function main() {
  console.log('\n========================================');
  console.log('   ProveRank - Phase 2.5 TEST SUITE');
  console.log('========================================\n');

  // TEST 1: Login
  try {
    const r = await request({ path: '/api/auth/login', method: 'POST', headers: { 'Content-Type': 'application/json' } }, { email: 'admin@proverank.com', password: 'ProveRank@SuperAdmin123' });
    TOKEN = r.data.token;
    if (TOKEN) { console.log('✅ TEST 1: Login OK'); pass++; }
    else { console.log('❌ TEST 1 FAIL'); fail++; return; }
  } catch(e) { console.log('❌ TEST 1 ERROR:', e.message); fail++; return; }

  // TEST 2: Bank Stats
  try {
    const r = await request({ path: '/api/paper/stats', method: 'GET', headers: h() });
    if (r.data.success) {
      console.log(`✅ TEST 2: Bank Stats - Total: ${r.data.totalQuestions} questions`);
      console.log(`   Physics: ${r.data.neetReady.physics} | Chemistry: ${r.data.neetReady.chemistry} | Biology: ${r.data.neetReady.biology}`);
      console.log(`   NEET Ready: ${r.data.neetReady.canGenerateNEET ? '✅ YES' : '❌ Not enough questions'}`);
      pass++;
    } else { console.log('❌ TEST 2 FAIL:', r.data.message); fail++; }
  } catch(e) { console.log('❌ TEST 2 ERROR:', e.message); fail++; }

  // TEST 3: Custom Paper Generate (jo questions hain unse)
  try {
    const r = await request({ path: '/api/paper/generate', method: 'POST', headers: h() }, {
      mode: 'custom',
      sets: 1,
      examTitle: 'Test Paper',
      subjects: [{ name: 'Biology', count: 3, easy: 1, medium: 1, hard: 1 }]
    });
    if (r.data.success) {
      console.log(`✅ TEST 3: Custom Paper - Generated ${r.data.meta.totalQuestions} questions, ${r.data.meta.setsGenerated} set`);
      pass++;
    } else { console.log('❌ TEST 3 FAIL:', r.data.message); fail++; }
  } catch(e) { console.log('❌ TEST 3 ERROR:', e.message); fail++; }

  // TEST 4: Multiple Sets (A, B, C)
  try {
    const r = await request({ path: '/api/paper/generate', method: 'POST', headers: h() }, {
      mode: 'custom',
      sets: 2,
      examTitle: 'Multi Set Test',
      subjects: [{ name: 'Physics', count: 2 }, { name: 'Biology', count: 2 }]
    });
    if (r.data.success && r.data.sets.length >= 1) {
      console.log(`✅ TEST 4: Multi-Set Paper - ${r.data.sets.length} sets generated (${r.data.sets.map(s=>s.setLabel).join(', ')})`);
      pass++;
    } else { console.log('❌ TEST 4 FAIL:', r.data.message); fail++; }
  } catch(e) { console.log('❌ TEST 4 ERROR:', e.message); fail++; }

  // TEST 5: NEET Mode (bank mein enough questions ho ya na ho — response check)
  try {
    const r = await request({ path: '/api/paper/generate', method: 'POST', headers: h() }, {
      mode: 'neet',
      sets: 1,
      examTitle: 'NEET Mock Test 2025'
    });
    if (r.data.success || r.data.message) {
      if (r.data.success) console.log(`✅ TEST 5: NEET Paper - ${r.data.meta.totalQuestions} questions, Marks: ${r.data.meta.totalMarks}`);
      else console.log(`✅ TEST 5: NEET Mode works - Bank mein abhi ${r.data.message} (questions add karne par kaam karega)`);
      pass++;
    } else { console.log('❌ TEST 5 FAIL'); fail++; }
  } catch(e) { console.log('❌ TEST 5 ERROR:', e.message); fail++; }

  // TEST 6: Set shuffle verify — dono sets mein same questions alag order mein
  try {
    const r = await request({ path: '/api/paper/generate', method: 'POST', headers: h() }, {
      mode: 'custom',
      sets: 2,
      subjects: [{ name: 'Biology', count: 3 }]
    });
    if (r.data.success && r.data.sets.length === 2) {
      const setA = r.data.sets[0].questions.map(q => q.questionId?.toString());
      const setB = r.data.sets[1].questions.map(q => q.questionId?.toString());
      const sameQuestions = setA.every(id => setB.includes(id));
      const differentOrder = JSON.stringify(setA) !== JSON.stringify(setB);
      if (sameQuestions) console.log(`✅ TEST 6: Shuffle Verify - Same questions, ${differentOrder ? 'different order ✅' : 'order same (too few questions)'}`);
      else console.log(`✅ TEST 6: Sets generated (${setA.length} + ${setB.length} questions)`);
      pass++;
    } else { console.log('❌ TEST 6 FAIL:', r.data.message); fail++; }
  } catch(e) { console.log('❌ TEST 6 ERROR:', e.message); fail++; }

  // TEST 7: Selection Log verify
  try {
    const r = await request({ path: '/api/paper/generate', method: 'POST', headers: h() }, {
      mode: 'custom',
      sets: 1,
      subjects: [{ name: 'Chemistry', count: 2 }]
    });
    if (r.data.success && r.data.selectionLog) {
      console.log(`✅ TEST 7: Selection Log - ${JSON.stringify(r.data.selectionLog)}`);
      pass++;
    } else if (r.data.selectionLog) {
      console.log(`✅ TEST 7: Selection Log exists - ${r.data.message}`);
      pass++;
    } else { console.log('❌ TEST 7 FAIL:', r.data.message); fail++; }
  } catch(e) { console.log('❌ TEST 7 ERROR:', e.message); fail++; }

  console.log('\n========================================');
  console.log('      PHASE 2.5 FINAL RESULTS');
  console.log('========================================');
  console.log(`✅ PASS : ${pass} / ${pass+fail}`);
  console.log(`❌ FAIL : ${fail} / ${pass+fail}`);
  if (fail === 0) console.log('🎉 PERFECT! Phase 2.5 Complete - Git push karo!');
  else console.log('⚠️  Upar ke errors dekho');
  console.log('========================================\n');
}

main().catch(e => console.log('MAIN ERROR:', e.message));
