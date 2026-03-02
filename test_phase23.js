const http = require('http');
const fs = require('fs');
const path = require('path');
const XLSX = require('xlsx');

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
    if (body) req.write(typeof body === 'string' ? body : JSON.stringify(body));
    req.end();
  });
}

function multipartRequest(urlPath, filePath, token) {
  return new Promise((resolve, reject) => {
    const boundary = '----FormBoundary' + Date.now();
    const fileContent = fs.readFileSync(filePath);
    const filename = path.basename(filePath);
    const pre = Buffer.from(`--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="${filename}"\r\nContent-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet\r\n\r\n`);
    const post = Buffer.from(`\r\n--${boundary}--\r\n`);
    const bodyBuf = Buffer.concat([pre, fileContent, post]);
    const req = http.request({
      host: HOST, port: PORT, path: urlPath, method: 'POST',
      headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': `multipart/form-data; boundary=${boundary}`, 'Content-Length': bodyBuf.length }
    }, res => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, data: JSON.parse(data) }); }
        catch(e) { resolve({ status: res.statusCode, data: { raw: data } }); }
      });
    });
    req.on('error', reject);
    req.write(bodyBuf);
    req.end();
  });
}

function makeQExcel(fp) {
  const data = [
    ['Question Text','Option A','Option B','Option C','Option D','Correct Answer','Subject','Chapter','Difficulty','Explanation'],
    ['Mitochondria ka kya kaam hai?','Energy produce karna','Protein synthesis','DNA store','Cell division','A','Biology','Cell Biology','Easy','Powerhouse of cell'],
    ['Newton ka pehla niyam?','F=ma','Inertia','Action reaction','Gravitation','B','Physics','Laws of Motion','Medium','Inertia law']
  ];
  const ws = XLSX.utils.aoa_to_sheet(data);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, 'Questions');
  XLSX.writeFile(wb, fp);
}

function makeSExcel(fp) {
  const data = [
    ['Name','Email','Phone','Group'],
    ['Rahul Test','rahultest23x@gmail.com','9876543210','NEET 2025'],
    ['Priya Test','priyatest23x@gmail.com','9876543211','NEET 2025']
  ];
  const ws = XLSX.utils.aoa_to_sheet(data);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, 'Students');
  XLSX.writeFile(wb, fp);
}

async function main() {
  console.log('\n========================================');
  console.log('   ProveRank - Phase 2.3 TEST SUITE');
  console.log('========================================\n');

  // TEST 1: Login
  try {
    const r = await request(
      { path: '/api/auth/login', method: 'POST', headers: { 'Content-Type': 'application/json' } },
      { email: 'admin@proverank.com', password: 'ProveRank@SuperAdmin123' }
    );
    TOKEN = r.data.token;
    if (TOKEN) { console.log('✅ TEST 1: Login OK'); pass++; }
    else { console.log('❌ TEST 1: Login FAIL', r.data); fail++; return; }
  } catch(e) { console.log('❌ TEST 1 ERROR:', e.message); fail++; return; }

  const qFile = '/home/runner/workspace/test_q23.xlsx';
  const sFile = '/home/runner/workspace/test_s23.xlsx';
  makeQExcel(qFile);
  makeSExcel(sFile);

  // TEST 2: Excel Question Upload
  try {
    const r = await multipartRequest('/api/upload/excel/questions', qFile, TOKEN);
    if (r.data.success) { console.log(`✅ TEST 2: Excel Question Upload OK (inserted: ${r.data.inserted || r.data.successCount || '?'})`); pass++; }
    else { console.log('❌ TEST 2 FAIL:', r.data.message || JSON.stringify(r.data)); fail++; }
  } catch(e) { console.log('❌ TEST 2 ERROR:', e.message); fail++; }

  // TEST 3: Excel Student Bulk Import
  try {
    const r = await multipartRequest('/api/upload/excel/students', sFile, TOKEN);
    if (r.data.success) { console.log(`✅ TEST 3: Student Bulk Import OK (inserted: ${r.data.inserted || r.data.successCount || '?'})`); pass++; }
    else { console.log('❌ TEST 3 FAIL:', r.data.message || JSON.stringify(r.data)); fail++; }
  } catch(e) { console.log('❌ TEST 3 ERROR:', e.message); fail++; }

  // TEST 4: Duplicate Student Detect — same file dobara bhejo
  try {
    const r = await multipartRequest('/api/upload/excel/students', sFile, TOKEN);
    // Success hona chahiye BUT inserted:0 aur errors array mein duplicates
    const hasErrors = (r.data.errors && r.data.errors.length > 0) || 
                      (r.data.errorDetails && r.data.errorDetails.length > 0) ||
                      (r.data.errorCount && r.data.errorCount > 0);
    if (r.data.success && hasErrors) {
      const count = (r.data.errors && r.data.errors.length) || r.data.errorCount || r.data.errorDetails?.length || '?';
      console.log(`✅ TEST 4: Duplicate Email Detect - ${count} duplicates caught`); pass++;
    } else {
      console.log('❌ TEST 4 FAIL:', JSON.stringify(r.data)); fail++;
    }
  } catch(e) { console.log('❌ TEST 4 ERROR:', e.message); fail++; }

  // TEST 5: Copy-Paste Preview
  try {
    const r = await request(
      { path: '/api/upload/copypaste/questions', method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${TOKEN}` } },
      { questionsText: '1. Pani ka formula kya hai?\nA) H2O\nB) CO2\nC) O2\nD) N2', answerKeyText: '1-A', subject: 'Chemistry', preview: true }
    );
    if (r.data.success && r.data.preview) { console.log(`✅ TEST 5: Copy-Paste Preview - Found: ${r.data.questionsFound}`); pass++; }
    else { console.log('❌ TEST 5 FAIL:', r.data.message || JSON.stringify(r.data)); fail++; }
  } catch(e) { console.log('❌ TEST 5 ERROR:', e.message); fail++; }

  // TEST 6: Copy-Paste Save
  try {
    const r = await request(
      { path: '/api/upload/copypaste/questions', method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${TOKEN}` } },
      { questionsText: '1. Surya ka nearest planet koi sa hai?\nA) Earth\nB) Venus\nC) Mercury\nD) Mars', answerKeyText: '1-C', subject: 'Science', preview: false }
    );
    if (r.data.success && !r.data.preview) { console.log(`✅ TEST 6: Copy-Paste Save - Inserted: ${r.data.inserted}`); pass++; }
    else { console.log('❌ TEST 6 FAIL:', r.data.message || JSON.stringify(r.data)); fail++; }
  } catch(e) { console.log('❌ TEST 6 ERROR:', e.message); fail++; }

  // TEST 7: PDF Route Accessible
  try {
    const r = await request({ path: '/api/upload/pdf/questions', method: 'POST', headers: { 'Authorization': `Bearer ${TOKEN}` } });
    if (r.status === 400 || r.status === 200) { console.log('✅ TEST 7: PDF Upload route accessible'); pass++; }
    else { console.log('❌ TEST 7 FAIL status:', r.status); fail++; }
  } catch(e) { console.log('❌ TEST 7 ERROR:', e.message); fail++; }

  // TEST 8: Upload Logs
  try {
    const r = await request({ path: '/api/excel/logs', method: 'GET', headers: { 'Authorization': `Bearer ${TOKEN}` } });
    if (r.data.success) { console.log(`✅ TEST 8: Upload Logs - ${r.data.logs.length} logs`); pass++; }
    else { console.log('❌ TEST 8 FAIL:', r.data.message || JSON.stringify(r.data)); fail++; }
  } catch(e) { console.log('❌ TEST 8 ERROR:', e.message); fail++; }

  // Cleanup
  [qFile, sFile].forEach(f => { try { fs.unlinkSync(f); } catch(e) {} });

  console.log('\n========================================');
  console.log('      PHASE 2.3 FINAL RESULTS');
  console.log('========================================');
  console.log(`✅ PASS : ${pass} / ${pass+fail}`);
  console.log(`❌ FAIL : ${fail} / ${pass+fail}`);
  if (fail === 0) console.log('🎉 PERFECT! Phase 2.3 Complete - Git push karo!');
  else console.log('⚠️  Upar ke errors dekho');
  console.log('========================================\n');
}

main().catch(e => console.log('MAIN ERROR:', e.message));
