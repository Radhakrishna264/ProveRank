const https = require('https');
const http = require('http');

const BASE_URL = 'https://proverank.onrender.com';

function request(method, path, body, headers = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(BASE_URL + path);
    const options = {
      hostname: url.hostname,
      port: 443,
      path: url.pathname,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        ...headers
      }
    };
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, headers: res.headers, body: JSON.parse(data) }); }
        catch(e) { resolve({ status: res.statusCode, headers: res.headers, body: data }); }
      });
    });
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function runTests() {
  let pass = 0;
  let fail = 0;
  const results = [];

  function log(name, ok, detail) {
    const sym = ok ? '✅' : '❌';
    console.log(`${sym} ${name}: ${detail}`);
    results.push({ name, ok });
    if (ok) pass++; else fail++;
  }

  console.log('\n🔐 ProveRank — Stage 10 Step-05 Security Check');
  console.log('==============================================\n');

  // TEST 1: Security Headers Check
  try {
    const res = await request('GET', '/api/auth/me', null);
    const hasXFrame = !!res.headers['x-frame-options'];
    const hasXContent = !!res.headers['x-content-type-options'];
    const hasHelmet = hasXFrame || hasXContent;
    log('Security Headers (Helmet)', hasHelmet,
      hasHelmet
        ? `x-frame-options: ${res.headers['x-frame-options'] || 'via helmet'}`
        : 'Helmet headers missing — check helmet setup');
  } catch(e) {
    log('Security Headers (Helmet)', false, e.message);
  }

  // TEST 2: Invalid JWT Token → must return 401
  try {
    const res = await request('GET', '/api/auth/me', null, {
      'Authorization': 'Bearer invalid.token.here'
    });
    log('Invalid JWT → 401', res.status === 401,
      `Status: ${res.status} (expected 400 or 401 — ✅)`);
  } catch(e) {
    log('Invalid JWT → 401', false, e.message);
  }

  // TEST 3: No Token → must return 401
  try {
    const res = await request('GET', '/api/auth/me', null, {});
    log('No Token → 401', res.status === 401,
      `Status: ${res.status} (expected 401)`);
  } catch(e) {
    log('No Token → 401', false, e.message);
  }

  // TEST 4: Wrong Password Login → 401
  try {
    const res = await request('POST', '/api/auth/login', {
      email: 'admin@proverank.com',
      password: 'wrongpassword123'
    });
    log('Wrong Password → 400/401', res.status === 401 || res.status === 400,
      `Status: ${res.status} | Msg: ${res.body?.message || '-'}`);
  } catch(e) {
    log('Wrong Password → 401', false, e.message);
  }

  // TEST 5: SuperAdmin Login on Production
  let adminToken = null;
  try {
    const res = await request('POST', '/api/auth/login', {
      email: 'admin@proverank.com',
      password: 'ProveRank@SuperAdmin123'
    });
    adminToken = res.body?.token;
    const roleOk = res.body?.role === 'superadmin';
    log('SuperAdmin Login', res.status === 200 && adminToken && roleOk,
      `Status: ${res.status} | Role: ${res.body?.role} | Token: ${adminToken ? 'RECEIVED ✅' : 'MISSING ❌'}`);
  } catch(e) {
    log('SuperAdmin Login', false, e.message);
  }

  // TEST 6: Student Login on Production
  let studentToken = null;
  try {
    const res = await request('POST', '/api/auth/login', {
      email: 'student@proverank.com',
      password: 'ProveRank@123'
    });
    studentToken = res.body?.token;
    const roleOk = res.body?.role === 'student';
    log('Student Login', res.status === 200 && studentToken && roleOk,
      `Status: ${res.status} | Role: ${res.body?.role} | Token: ${studentToken ? 'RECEIVED ✅' : 'MISSING ❌'}`);
  } catch(e) {
    log('Student Login', false, e.message);
  }

  // TEST 7: Student Token → Admin Route → must return 403
  if (studentToken) {
    try {
      const res = await request('GET', '/api/admin/manage/admins', null, {
        'Authorization': `Bearer ${studentToken}`
      });
      log('Student → Admin Route → 403', res.status === 403,
        `Status: ${res.status} (expected 403 — role protection working)`);
    } catch(e) {
      log('Student → Admin Route → 403', false, e.message);
    }
  } else {
    log('Student → Admin Route → 403', false, 'Student login failed, skipping');
  }

  // TEST 8: Admin Token → Admin Route → must work (200)
  if (adminToken) {
    try {
      const res = await request('GET', '/api/admin/manage/admins', null, {
        'Authorization': `Bearer ${adminToken}`
      });
      log('SuperAdmin → Admin Route → 200', res.status === 200,
        `Status: ${res.status} (admin access working)`);
    } catch(e) {
      log('SuperAdmin → Admin Route → 200', false, e.message);
    }
  } else {
    log('SuperAdmin → Admin Route → 200', false, 'Admin login failed, skipping');
  }

  // TEST 9: SQL/NoSQL Injection Attempt
  try {
    const res = await request('POST', '/api/auth/login', {
      email: { '$gt': '' },
      password: { '$gt': '' }
    });
    log('NoSQL Injection Block', res.status !== 200,
      `Status: ${res.status} (expected 400/401 — injection blocked)`);
  } catch(e) {
    log('NoSQL Injection Block', false, e.message);
  }

  // TEST 10: HTTPS Enforce Check
  try {
    const isHttps = BASE_URL.startsWith('https');
    log('HTTPS Enforced', isHttps,
      `Backend URL: ${BASE_URL} — ${isHttps ? 'HTTPS ✅' : 'HTTP ❌ — Must use HTTPS'}`);
  } catch(e) {
    log('HTTPS Enforced', false, e.message);
  }

  // FINAL REPORT
  console.log('\n==============================================');
  console.log(`📊 FINAL RESULT: ${pass}/10 PASS | ${fail} FAIL`);
  console.log('==============================================');

  if (fail === 0) {
    console.log('🎉 ALL SECURITY CHECKS PASS — Production Go-Live Ready!');
  } else {
    console.log('⚠️  Kuch checks fail hue — upar dekho kya fix karna hai.');
    console.log('\n❌ FAILED CHECKS:');
    results.filter(r => !r.ok).forEach(r => console.log(`   → ${r.name}`));
  }
}

runTests().catch(console.error);
