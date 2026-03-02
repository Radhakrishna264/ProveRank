const mongoose = require('mongoose');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const BASE = 'http://localhost:3000/api';
let TOKEN = '';

async function getToken() {
  const res = await fetch(`${BASE}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'admin@proverank.com', password: 'ProveRank@SuperAdmin123' })
  });
  const data = await res.json();
  return data.token;
}

async function test(name, fn) {
  try {
    const ok = await fn();
    if (ok) console.log(`✅ PASS — ${name}`);
    else console.log(`❌ FAIL — ${name}`);
    return ok;
  } catch(e) {
    console.log(`❌ ERROR — ${name}: ${e.message}`);
    return false;
  }
}

async function main() {
  console.log('================================================');
  console.log('   ProveRank — Phase 2.3 Complete Test Suite');
  console.log('================================================\n');

  TOKEN = await getToken();
  if (!TOKEN) { console.log('❌ Login failed!'); process.exit(1); }
  console.log('✅ Login OK!\n');

  let pass = 0, fail = 0;
  const results = [];

  // TEST 1: Upload route exist check
  const t1 = await test('TEST 1: Upload route /api/upload accessible', async () => {
    const res = await fetch(`${BASE}/upload/excel/questions`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${TOKEN}` }
    });
    // 400 = route exists but no file sent (expected)
    return res.status === 400 || res.status === 200;
  });
  t1 ? pass++ : fail++;

  // TEST 2: Excel Questions — create test Excel file
  const t2 = await test('TEST 2: Excel Question Upload (XLSX parse)', async () => {
    // Create a simple CSV-style test
    const XLSX = require('xlsx');
    const wsData = [
      ['text','optionA','optionB','optionC','optionD','correct','subject','chapter','difficulty','type'],
      ['Newton ka pehla niyam kya hai?','Inertia','Force','Energy','Power','0','Physics','Laws of Motion','Medium','SCQ'],
      ['Photosynthesis mein kya banta hai?','CO2','O2','N2','H2','1','Biology','Plant Biology','Easy','SCQ'],
      ['Acid ki pH value kya hoti hai?','7 se zyada','7 se kam','Exactly 7','0','Chemistry','Acids Bases','Easy','SCQ'],
    ];
    const ws = XLSX.utils.aoa_to_sheet(wsData);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Questions');
    XLSX.writeFile(wb, '/home/runner/workspace/test_questions.xlsx');

    // Upload via multipart
    const FormData = require('form-data');
    const form = new FormData();
    form.append('file', fs.createReadStream('/home/runner/workspace/test_questions.xlsx'));

    const res = await fetch(`${BASE}/upload/excel/questions`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${TOKEN}`, ...form.getHeaders() },
      body: form
    });
    const data = await res.json();
    console.log(`         Inserted: ${data.inserted}, Errors: ${data.errors}`);
    return data.success && data.inserted > 0;
  });
  t2 ? pass++ : fail++;

  // TEST 3: Excel Students Upload
  const t3 = await test('TEST 3: Excel Student Bulk Import (S8)', async () => {
    const XLSX = require('xlsx');
    const wsData = [
      ['name','email','phone','group'],
      ['Rahul Sharma','rahul.test23@test.com','9876543210','Batch A'],
      ['Priya Singh','priya.test23@test.com','9876543211','Batch A'],
      ['Amit Kumar','amit.test23@test.com','9876543212','Batch B'],
    ];
    const ws = XLSX.utils.aoa_to_sheet(wsData);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Students');
    XLSX.writeFile(wb, '/home/runner/workspace/test_students.xlsx');

    const FormData = require('form-data');
    const form = new FormData();
    form.append('file', fs.createReadStream('/home/runner/workspace/test_students.xlsx'));

    const res = await fetch(`${BASE}/upload/excel/students`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${TOKEN}`, ...form.getHeaders() },
      body: form
    });
    const data = await res.json();
    console.log(`         Inserted: ${data.inserted}, Errors: ${data.errors}`);
    console.log(`         Message: ${data.message}`);
    return data.success && data.inserted > 0;
  });
  t3 ? pass++ : fail++;

  // TEST 4: Duplicate student check
  const t4 = await test('TEST 4: Duplicate Student Email Detect', async () => {
    const XLSX = require('xlsx');
    const wsData = [
      ['name','email','phone'],
      ['Rahul Sharma','rahul.test23@test.com','9876543210'],
    ];
    const ws = XLSX.utils.aoa_to_sheet(wsData);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Students');
    XLSX.writeFile(wb, '/home/runner/workspace/test_dup.xlsx');

    const FormData = require('form-data');
    const form = new FormData();
    form.append('file', fs.createReadStream('/home/runner/workspace/test_dup.xlsx'));

    const res = await fetch(`${BASE}/upload/excel/students`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${TOKEN}`, ...form.getHeaders() },
      body: form
    });
    const data = await res.json();
    console.log(`         Errors: ${data.errors}, ErrorDetails: ${JSON.stringify(data.errorDetails)}`);
    return data.errors > 0;
  });
  t4 ? pass++ : fail++;

  // TEST 5: Copy-Paste Preview Mode
  const t5 = await test('TEST 5: Copy-Paste Preview Mode', async () => {
    const res = await fetch(`${BASE}/upload/copypaste/questions`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${TOKEN}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        questionsText: `1. Digestive system ka main organ kaun sa hai?
A) Heart
B) Liver
C) Stomach
D) Kidney

2. Sound ki speed hawa mein kitni hoti hai?
A) 300 m/s
B) 343 m/s
C) 500 m/s
D) 1000 m/s`,
        answerKeyText: `1-C
2-B`,
        subject: 'Biology',
        preview: true
      })
    });
    const data = await res.json();
    console.log(`         Questions found: ${data.questionsFound}`);
    console.log(`         Preview[0]: ${data.preview?.[0]?.text?.substring(0,50)}`);
    return data.success && data.questionsFound >= 2;
  });
  t5 ? pass++ : fail++;

  // TEST 6: Copy-Paste Save Mode
  const t6 = await test('TEST 6: Copy-Paste Save (with Answer Key)', async () => {
    const res = await fetch(`${BASE}/upload/copypaste/questions`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${TOKEN}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        questionsText: `1. Digestive system ka main organ kaun sa hai?
A) Heart
B) Liver
C) Stomach
D) Kidney

2. Sound ki speed hawa mein kitni hoti hai?
A) 300 m/s
B) 343 m/s
C) 500 m/s
D) 1000 m/s`,
        answerKeyText: `1-C
2-B`,
        subject: 'Biology',
        chapter: 'Human Body',
        difficulty: 'Easy',
        preview: false
      })
    });
    const data = await res.json();
    console.log(`         Inserted: ${data.inserted}, Skipped: ${data.skipped}`);
    return data.success && data.inserted > 0;
  });
  t6 ? pass++ : fail++;

  // TEST 7: PDF Upload route accessible
  const t7 = await test('TEST 7: PDF Upload route accessible', async () => {
    const res = await fetch(`${BASE}/upload/pdf/questions`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${TOKEN}` }
    });
    return res.status === 400 || res.status === 200;
  });
  t7 ? pass++ : fail++;

  console.log('\n================================================');
  console.log('         PHASE 2.3 TEST RESULTS');
  console.log('================================================');
  console.log(`✅ PASS : ${pass} / 7`);
  console.log(`❌ FAIL : ${fail} / 7`);
  if (fail === 0) console.log('🎉 PERFECT! Phase 2.3 complete — Git push karo!');
  else console.log('⚠️  Fail wale results copy karke bhejo!');
  console.log('================================================');

  // Cleanup test files
  ['/home/runner/workspace/test_questions.xlsx',
   '/home/runner/workspace/test_students.xlsx',
   '/home/runner/workspace/test_dup.xlsx'].forEach(f => {
    if (fs.existsSync(f)) fs.unlinkSync(f);
  });
}

main().catch(e => console.log('Error:', e.message));
