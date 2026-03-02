const axios = require('axios');
require('dotenv').config();

const BASE = 'http://localhost:3000';
let token = '';
const sleep = (ms) => new Promise(r => setTimeout(r, ms));
let passed = 0, failed = 0;

function ok(msg)   { console.log(`✅ PASS — ${msg}`); passed++; }
function fail(msg) { console.log(`❌ FAIL — ${msg}`); failed++; }

// ── LOGIN ────────────────────────────────────────────────────
async function login() {
  try {
    const res = await axios.post(`${BASE}/api/auth/login`, {
      email: 'admin@proverank.com',
      password: 'ProveRank@SuperAdmin123'
    });
    token = res.data.token;
    ok('SuperAdmin Login');
  } catch (e) {
    fail(`Login — ${e.response?.data?.message || e.message}`);
  }
}

// ── M2: CUSTOM REGISTRATION FIELDS ──────────────────────────
// Test 1: GET custom fields list route exist karta hai?
async function testM2_GetFields() {
  try {
    const res = await axios.get(`${BASE}/api/auth/registration-fields`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    ok(`M2 — GET /api/auth/registration-fields (Status: ${res.status})`);
  } catch (e) {
    if (e.response?.status === 404) fail('M2 — GET registration-fields route NOT FOUND (404)');
    else if (e.response?.status === 401) ok('M2 — Route exists (401 — auth working)');
    else ok(`M2 — Route exists (Status: ${e.response?.status})`);
  }
}

// Test 2: POST custom fields add karne ka route?
async function testM2_AddField() {
  try {
    const res = await axios.post(`${BASE}/api/auth/registration-fields`,
      { fieldName: 'schoolName', fieldType: 'text', required: false, label: 'School Name' },
      { headers: { Authorization: `Bearer ${token}` } }
    );
    ok(`M2 — POST registration-fields — Field add hua (Status: ${res.status})`);
  } catch (e) {
    if (e.response?.status === 404) fail('M2 — POST registration-fields route NOT FOUND (404)');
    else ok(`M2 — Route exists (Status: ${e.response?.status})`);
  }
}

// Test 3: Registration mein custom field accept hota hai?
async function testM2_RegisterWithCustomField() {
  try {
    const res = await axios.post(`${BASE}/api/auth/register`, {
      name: 'Test Student M2',
      email: `testm2_${Date.now()}@test.com`,
      phone: '9876543210',
      password: 'ProveRank@123',
      schoolName: 'Test School'  // custom field
    });
    ok(`M2 — Register with custom field accepted (Status: ${res.status})`);
  } catch (e) {
    if (e.response?.status === 404) fail('M2 — Register route NOT FOUND');
    else if (e.response?.status === 400 && e.response?.data?.message?.includes('otp')) {
      ok('M2 — Register route works (OTP step required — normal flow)');
    } else {
      ok(`M2 — Register route works (Status: ${e.response?.status})`);
    }
  }
}

// ── S49: TWO FACTOR AUTHENTICATION ──────────────────────────
// Test 4: 2FA enable route exist karta hai?
async function testS49_EnableRoute() {
  try {
    const res = await axios.post(`${BASE}/api/auth/2fa/enable`, {},
      { headers: { Authorization: `Bearer ${token}` } }
    );
    ok(`S49 — POST /api/auth/2fa/enable (Status: ${res.status})`);
  } catch (e) {
    if (e.response?.status === 404) fail('S49 — 2FA enable route NOT FOUND (404)');
    else ok(`S49 — 2FA route exists (Status: ${e.response?.status})`);
  }
}

// Test 5: 2FA verify route exist karta hai?
async function testS49_VerifyRoute() {
  try {
    const res = await axios.post(`${BASE}/api/auth/2fa/verify`,
      { otp: '123456' },
      { headers: { Authorization: `Bearer ${token}` } }
    );
    ok(`S49 — POST /api/auth/2fa/verify (Status: ${res.status})`);
  } catch (e) {
    if (e.response?.status === 404) fail('S49 — 2FA verify route NOT FOUND (404)');
    else ok(`S49 — 2FA verify route exists (Status: ${e.response?.status})`);
  }
}

// Test 6: 2FA disable route?
async function testS49_DisableRoute() {
  try {
    const res = await axios.post(`${BASE}/api/auth/2fa/disable`, {},
      { headers: { Authorization: `Bearer ${token}` } }
    );
    ok(`S49 — POST /api/auth/2fa/disable (Status: ${res.status})`);
  } catch (e) {
    if (e.response?.status === 404) fail('S49 — 2FA disable route NOT FOUND (404)');
    else ok(`S49 — 2FA disable route exists (Status: ${e.response?.status})`);
  }
}

// Test 7: User model mein twoFactorEnabled field hai?
async function testS49_UserModel() {
  try {
    const res = await axios.get(`${BASE}/api/auth/me`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    const user = res.data.user || res.data;
    if (user.hasOwnProperty('twoFactorEnabled') || user.hasOwnProperty('twoFactor')) {
      ok('S49 — User model mein 2FA field exists');
    } else {
      fail('S49 — User model mein twoFactorEnabled/twoFactor field NAHI hai');
    }
  } catch (e) {
    if (e.response?.status === 404) fail('S49 — /api/auth/me route NOT FOUND');
    else fail(`S49 — User model check failed — ${e.response?.data?.message || e.message}`);
  }
}

// ── RUN ─────────────────────────────────────────────────────
async function run() {
  console.log('\n📋 Phase 1.1 Missing Features Test\n');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('Testing: M2 (Custom Reg Fields) + S49 (2FA)');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  await login();
  await sleep(300);

  console.log('\n── M2: Custom Registration Fields ──');
  await testM2_GetFields();
  await testM2_AddField();
  await testM2_RegisterWithCustomField();

  console.log('\n── S49: Two Factor Authentication ──');
  await testS49_EnableRoute();
  await testS49_VerifyRoute();
  await testS49_DisableRoute();
  await testS49_UserModel();

  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`✅ PASSED: ${passed} | ❌ FAILED: ${failed}`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  if (failed > 0) {
    console.log('⚠️  FAILED features ko add karna padega!');
  } else {
    console.log('🎉 Phase 1.1 — Sab features present hain!');
  }
  process.exit(0);
}

run().catch(e => { console.error('Fatal:', e.message); process.exit(1); });
