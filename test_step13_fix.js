const http = require('http');

function req(method, path, body, token) {
  return new Promise((resolve) => {
    const data = body ? JSON.stringify(body) : null;
    const opts = {
      hostname: 'localhost', port: 3000, path, method,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {})
      }
    };
    const r = http.request(opts, (res) => {
      let raw = '';
      res.on('data', d => raw += d);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(raw) }); }
        catch { resolve({ status: res.statusCode, body: raw }); }
      });
    });
    r.on('error', e => resolve({ status: 0, body: e.message }));
    if (data) r.write(data);
    r.end();
  });
}

async function run() {
  const login = await req('POST', '/api/auth/login', {
    email: 'admin@proverank.com', password: 'ProveRank@SuperAdmin123'
  });
  const token = login.body.token;

  // Get any question id first
  const list = await req('GET', '/api/questions?limit=1', null, token);
  const qid = list.body?.questions?.[0]?._id || list.body?.[0]?._id;
  console.log('Using questionId:', qid);

  if (!qid) { console.log('❌ No question found'); return; }

  // Step 13 — correct route is /:id/usage
  const usage = await req('GET', `/api/questions/${qid}/usage`, null, token);
  console.log('Step 13 /usage status:', usage.status);
  console.log('Step 13 body:', JSON.stringify(usage.body).substring(0, 150));

  if (usage.status === 200) {
    console.log('✅ Step 13: Usage Tracker OK |', JSON.stringify(usage.body).substring(0,80));
  } else {
    console.log('❌ Step 13 FAIL');
  }
}

run().catch(e => console.error('FATAL:', e));
