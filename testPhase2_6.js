const mongoose = require('mongoose');
const axios = require('axios');
const fs = require('fs');
require('dotenv').config();

const BASE = 'http://localhost:3000';
let token = '';

const sleep = (ms) => new Promise(r => setTimeout(r, ms));

async function login() {
  const res = await axios.post(`${BASE}/api/auth/login`, {
    email: 'admin@proverank.com',
    password: 'ProveRank@SuperAdmin123'
  });
  token = res.data.token;
  console.log('✅ Test 1 PASS — Login OK');
}

async function testCertificate() {
  try {
    const res = await axios.post(`${BASE}/api/pdf/certificate`, {
      studentName: 'Rahul Sharma',
      score: 580,
      date: new Date().toLocaleDateString('en-IN'),
      uniqueId: 'CERT-TEST-001'
    }, {
      headers: { Authorization: `Bearer ${token}` },
      responseType: 'arraybuffer'
    });
    fs.writeFileSync('/tmp/test_certificate.pdf', res.data);
    const size = fs.statSync('/tmp/test_certificate.pdf').size;
    if (size > 1000) {
      console.log(`✅ Test 2 PASS — Certificate PDF generated (${(size/1024).toFixed(1)} KB)`);
    } else {
      console.log('❌ Test 2 FAIL — Certificate PDF too small');
    }
  } catch (err) {
    console.log('❌ Test 2 FAIL —', err.response?.data?.message || err.message);
  }
}

async function testOMR() {
  try {
    const res = await axios.post(`${BASE}/api/pdf/omr`, {
      studentName: 'Priya Verma',
      examTitle: 'NEET Mock Test 2026',
      totalQuestions: 180,
      uniqueId: 'OMR-TEST-001'
    }, {
      headers: { Authorization: `Bearer ${token}` },
      responseType: 'arraybuffer'
    });
    fs.writeFileSync('/tmp/test_omr.pdf', res.data);
    const size = fs.statSync('/tmp/test_omr.pdf').size;
    if (size > 1000) {
      console.log(`✅ Test 3 PASS — OMR Sheet PDF generated (${(size/1024).toFixed(1)} KB)`);
    } else {
      console.log('❌ Test 3 FAIL — OMR PDF too small');
    }
  } catch (err) {
    console.log('❌ Test 3 FAIL —', err.response?.data?.message || err.message);
  }
}

async function testResultReport() {
  try {
    const res = await axios.post(`${BASE}/api/pdf/result`, {
      studentName: 'Arjun Singh',
      examTitle: 'NEET Mock Test 2026',
      score: 480,
      totalMarks: 720,
      correct: 120,
      wrong: 60,
      skipped: 0,
      rank: 5,
      uniqueId: 'RESULT-TEST-001',
      subject_scores: [
        { subject: 'Physics', score: 140, total: 180, correct: 35, wrong: 10 },
        { subject: 'Chemistry', score: 160, total: 180, correct: 40, wrong: 5 },
        { subject: 'Biology', score: 180, total: 360, correct: 45, wrong: 45 }
      ]
    }, {
      headers: { Authorization: `Bearer ${token}` },
      responseType: 'arraybuffer'
    });
    fs.writeFileSync('/tmp/test_result.pdf', res.data);
    const size = fs.statSync('/tmp/test_result.pdf').size;
    if (size > 500) {
      console.log(`✅ Test 4 PASS — Result Report PDF generated (${(size/1024).toFixed(1)} KB)`);
    } else {
      console.log('❌ Test 4 FAIL — Result PDF too small');
    }
  } catch (err) {
    console.log('❌ Test 4 FAIL —', err.response?.data?.message || err.message);
  }
}

async function checkPdfFolder() {
  const files = fs.readdirSync('/root/workspace/pdfs').filter(f => f.endsWith('.pdf'));
  console.log(`✅ Test 5 PASS — pdfs/ folder mein ${files.length} files saved:`, files);
}

async function run() {
  console.log('\n📋 Phase 2.6 — PDF Generation Test\n');
  await login();
  await sleep(500);
  await testCertificate();
  await sleep(500);
  await testOMR();
  await sleep(500);
  await testResultReport();
  await sleep(500);
  try { await checkPdfFolder(); } catch(e) { console.log('ℹ️  pdfs/ folder check skip —', e.message); }
  console.log('\n🏁 Phase 2.6 Test Complete!\n');
  process.exit(0);
}

run().catch(err => { console.error('Fatal:', err.message); process.exit(1); });
