const axios = require('axios');
require('dotenv').config();

const BASE = 'http://localhost:3000';
let token = '';
const sleep = (ms) => new Promise(r => setTimeout(r, ms));
let passed = 0, failed = 0;

function ok(msg)   { console.log(`✅ PASS — ${msg}`); passed++; }
function fail(msg) { console.log(`❌ FAIL — ${msg}`); failed++; }

async function login() {
  try {
    const res = await axios.post(`${BASE}/api/auth/login`, {
      email: 'admin@proverank.com', password: 'ProveRank@SuperAdmin123'
    });
    token = res.data.token;
    ok('SuperAdmin Login');
  } catch(e) { fail(`Login — ${e.message}`); }
}

async function testS37() {
  try {
    const res = await axios.post(`${BASE}/api/admin/manage/create-admin`,
      { name: 'Test Admin', email: `tadmin_${Date.now()}@test.com`,
        password: 'Test@1234', permissions: { canCreateExam: true } },
      { headers: { Authorization: `Bearer ${token}` } });
    ok(`S37 — POST create-admin (${res.status})`);
  } catch(e) {
    e.response?.status === 404 ? fail('S37 — create-admin NOT FOUND') :
    ok(`S37 — create-admin exists (${e.response?.status})`);
  }

  try {
    const res = await axios.get(`${BASE}/api/admin/manage/admins`,
      { headers: { Authorization: `Bearer ${token}` } });
    ok(`S37 — GET admins (${res.status}) — Count: ${res.data.count}`);
  } catch(e) {
    e.response?.status === 404 ? fail('S37 — GET admins NOT FOUND') :
    ok(`S37 — admins exists (${e.response?.status})`);
  }
}

async function testS72() {
  try {
    const res = await axios.put(`${BASE}/api/admin/manage/permissions/000000000000000000000001`,
      { permissions: { canCreateExam: false } },
      { headers: { Authorization: `Bearer ${token}` } });
    ok(`S72 — permissions (${res.status})`);
  } catch(e) {
    e.response?.status === 404 ? fail('S72 — permissions NOT FOUND') :
    ok(`S72 — permissions exists (${e.response?.status})`);
  }

  try {
    const res = await axios.put(`${BASE}/api/admin/manage/freeze/000000000000000000000001`,
      { frozen: true },
      { headers: { Authorization: `Bearer ${token}` } });
    ok(`S72 — freeze (${res.status})`);
  } catch(e) {
    e.response?.status === 404 ? fail('S72 — freeze NOT FOUND') :
    ok(`S72 — freeze exists (${e.response?.status})`);
  }
}

async function testS38() {
  try {
    const res = await axios.get(`${BASE}/api/admin/manage/activity-logs`,
      { headers: { Authorization: `Bearer ${token}` } });
    ok(`S38 — GET activity-logs (${res.status})`);
  } catch(e) {
    e.response?.status === 404 ? fail('S38 — activity-logs NOT FOUND') :
    ok(`S38 — activity-logs exists (${e.response?.status})`);
  }

  try {
    const res = await axios.post(`${BASE}/api/admin/manage/activity-logs`,
      { action: 'TEST', details: 'Test log', module: 'test' },
      { headers: { Authorization: `Bearer ${token}` } });
    ok(`S38 — POST activity-logs (${res.status})`);
  } catch(e) {
    e.response?.status === 404 ? fail('S38 — POST logs NOT FOUND') :
    ok(`S38 — POST logs exists (${e.response?.status})`);
  }
}

async function testS93() {
  try {
    const res = await axios.get(`${BASE}/api/admin/manage/audit-trail`,
      { headers: { Authorization: `Bearer ${token}` } });
    ok(`S93 — GET audit-trail (${res.status})`);
  } catch(e) {
    e.response?.status === 404 ? fail('S93 — audit-trail NOT FOUND') :
    ok(`S93 — audit-trail exists (${e.response?.status})`);
  }
}

async function testM4() {
  try {
    const res = await axios.post(`${BASE}/api/admin/manage/impersonate/000000000000000000000001`,
      {},
      { headers: { Authorization: `Bearer ${token}` } });
    ok(`M4 — impersonate (${res.status})`);
  } catch(e) {
    e.response?.status === 404 ? fail('M4 — impersonate NOT FOUND') :
    ok(`M4 — impersonate exists (${e.response?.status})`);
  }
}

async function run() {
  console.log('\n📋 Phase 1.2 — Missing Features Test\n');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  await login(); await sleep(300);

  console.log('\n── S37: SuperAdmin Add Admin ──');
  await testS37(); await sleep(200);

  console.log('\n── S72: Permission Control ──');
  await testS72(); await sleep(200);

  console.log('\n── S38: Admin Activity Logs ──');
  await testS38(); await sleep(200);

  console.log('\n── S93: Platform Audit Trail ──');
  await testS93(); await sleep(200);

  console.log('\n── M4: Student Login View ──');
  await testM4();

  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`✅ PASSED: ${passed} | ❌ FAILED: ${failed}`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  failed === 0
    ? console.log('🎉 Phase 1.2 — Sab features present hain!')
    : console.log('⚠️  Failed features fix karne padenge!');
  process.exit(0);
}

run().catch(e => { console.error('Fatal:', e.message); process.exit(1); });
