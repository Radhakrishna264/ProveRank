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
  // Login
  const login = await req('POST', '/api/auth/login', {
    email: 'admin@proverank.com', password: 'ProveRank@SuperAdmin123'
  });
  const token = login.body.token;
  console.log('Login:', login.status === 200 ? 'OK' : 'FAIL');

  // Step 22 — xmlData field (correct field name)
  const xmlStr = '<?xml version="1.0"?><quiz><question type="multichoice"><questiontext><text>What is H2O?</text></questiontext></question></quiz>';

  const r22 = await req('POST', '/api/questions/import/xml', {
    xmlData: xmlStr
  }, token);

  if (r22.status === 200 || r22.status === 201) {
    console.log('✅ Step 22: XML Import OK |', JSON.stringify(r22.body).substring(0, 80));
  } else {
    console.log('❌ Step 22: XML Import FAIL |', JSON.stringify(r22.body).substring(0, 120));
  }
}

run().catch(e => console.error('FATAL:', e));
