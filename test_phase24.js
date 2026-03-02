const http = require('http');

const HOST = 'localhost';
const PORT = 3000;
let TOKEN = '';
let pass = 0, fail = 0;

function request(options, body) {
  return new Promise((resolve, reject) => {
    const req = http.request({ host: HOST, port: PORT, ...options }, res => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, data: JSON.parse(data) }); }
        catch(e) { resolve({ status: res.statusCode, data: {} }); }
      });
    });
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

function jsonHeaders() {
  return { 'Content-Type': 'application/json', 'Authorization': `Bearer ${TOKEN}` };
}

async function main() {
  console.log('\n========================================');
  console.log('   ProveRank - Phase 2.4 TEST SUITE');
  console.log('========================================\n');

  // TEST 1: Login
  try {
    const r = await request(
      { path: '/api/auth/login', method: 'POST', headers: { 'Content-Type': 'application/json' } },
      { email: 'admin@proverank.com', password: 'ProveRank@SuperAdmin123' }
    );
    TOKEN = r.data.token;
    if (TOKEN) { console.log('✅ TEST 1: Login OK'); pass++; }
    else { console.log('❌ TEST 1: Login FAIL'); fail++; return; }
  } catch(e) { console.log('❌ TEST 1 ERROR:', e.message); fail++; return; }

  // TEST 2: Copy-Paste Preview Mode
  try {
    const r = await request(
      { path: '/api/upload/copypaste/questions', method: 'POST', headers: jsonHeaders() },
      {
        questionsText: '1. DNA ka full form kya hai?\nA) Deoxyribonucleic Acid\nB) Diribonucleic Acid\nC) Deoxyribose Acid\nD) None\n2. Cell ka powerhouse kya hai?\nA) Nucleus\nB) Mitochondria\nC) Ribosome\nD) Golgi',
        answerKeyText: '1-A\n2-B',
        subject: 'Biology',
        preview: true
      }
    );
    if (r.data.success && r.data.preview) { console.log(`✅ TEST 2: Copy-Paste Preview - ${r.data.questionsFound} questions found`); pass++; }
    else { console.log('❌ TEST 2 FAIL:', r.data.message || JSON.stringify(r.data)); fail++; }
  } catch(e) { console.log('❌ TEST 2 ERROR:', e.message); fail++; }

  // TEST 3: Copy-Paste Save
  try {
    const r = await request(
      { path: '/api/upload/copypaste/questions', method: 'POST', headers: jsonHeaders() },
      {
        questionsText: '1. Photosynthesis mein kaun sa gas produce hoti hai?\nA) CO2\nB) N2\nC) O2\nD) H2',
        answerKeyText: '1-C',
        subject: 'Biology',
        chapter: 'Photosynthesis',
        preview: false
      }
    );
    if (r.data.success && !r.data.preview) { console.log(`✅ TEST 3: Copy-Paste Save - Inserted: ${r.data.inserted}`); pass++; }
    else { console.log('❌ TEST 3 FAIL:', r.data.message || JSON.stringify(r.data)); fail++; }
  } catch(e) { console.log('❌ TEST 3 ERROR:', e.message); fail++; }

  // TEST 4: Validate + Error Highlighting (Phase 2.4 new feature)
  try {
    const r = await request(
      { path: '/api/upload/copypaste/validate', method: 'POST', headers: jsonHeaders() },
      {
        questionsText: '1. Gravitation ka niyam kisne diya?\nA) Newton\nB) Einstein\nC) Bohr\nD) Faraday\n2. Bad question\nA) only one option',
        answerKeyText: '1-A',
        subject: 'Physics'
      }
    );
    if (r.data.success && r.data.summary) {
      console.log(`✅ TEST 4: Validation - Parsed: ${r.data.summary.totalParsed}, Valid: ${r.data.summary.validQuestions}, Errors: ${r.data.summary.validationErrors}`);
      pass++;
    } else { console.log('❌ TEST 4 FAIL:', r.data.message || JSON.stringify(r.data)); fail++; }
  } catch(e) { console.log('❌ TEST 4 ERROR:', e.message); fail++; }

  // TEST 5: Validation catches errors properly
  try {
    const r = await request(
      { path: '/api/upload/copypaste/validate', method: 'POST', headers: jsonHeaders() },
      {
        questionsText: '1. Hi?\nA) Yes',
        answerKeyText: '',
        subject: 'Test'
      }
    );
    if (r.data.success && r.data.validationErrors && r.data.validationErrors.length > 0) {
      console.log(`✅ TEST 5: Error Highlighting - ${r.data.validationErrors.length} errors caught`); pass++;
    } else { console.log('❌ TEST 5 FAIL - errors nahi pakde:', JSON.stringify(r.data.summary)); fail++; }
  } catch(e) { console.log('❌ TEST 5 ERROR:', e.message); fail++; }

  // TEST 6: Result Calculation Link (without examId - should still work)
  try {
    const r = await request(
      { path: '/api/upload/copypaste/validate', method: 'POST', headers: jsonHeaders() },
      {
        questionsText: '1. Newton ka 2nd law kya hai?\nA) F=ma\nB) v=u+at\nC) p=mv\nD) E=mc2',
        answerKeyText: '1-A',
        subject: 'Physics'
      }
    );
    if (r.data.success && r.data.summary && r.data.summary.withAnswers > 0) {
      console.log(`✅ TEST 6: Result Calc Link - ${r.data.summary.withAnswers} questions with answers linked`); pass++;
    } else { console.log('❌ TEST 6 FAIL:', JSON.stringify(r.data)); fail++; }
  } catch(e) { console.log('❌ TEST 6 ERROR:', e.message); fail++; }

  // TEST 7: Answer Key Auto-Sync check
  try {
    const r = await request(
      { path: '/api/upload/copypaste/validate', method: 'POST', headers: jsonHeaders() },
      {
        questionsText: '1. Earth ka satellite kya hai?\nA) Sun\nB) Moon\nC) Mars\nD) Venus\n2. H2O kya hai?\nA) Acid\nB) Base\nC) Water\nD) Salt',
        answerKeyText: '1-B\n2-C',
        subject: 'General'
      }
    );
    if (r.data.success && r.data.summary.withAnswers === 2) {
      console.log(`✅ TEST 7: Answer Key Auto-Sync - Both questions synced`); pass++;
    } else { console.log('❌ TEST 7 FAIL:', JSON.stringify(r.data.summary)); fail++; }
  } catch(e) { console.log('❌ TEST 7 ERROR:', e.message); fail++; }

  console.log('\n========================================');
  console.log('      PHASE 2.4 FINAL RESULTS');
  console.log('========================================');
  console.log(`✅ PASS : ${pass} / ${pass+fail}`);
  console.log(`❌ FAIL : ${fail} / ${pass+fail}`);
  if (fail === 0) console.log('🎉 PERFECT! Phase 2.4 Complete - Git push karo!');
  else console.log('⚠️  Upar ke errors dekho');
  console.log('========================================\n');
}

main().catch(e => console.log('MAIN ERROR:', e.message));
