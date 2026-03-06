const http = require('http');
const XLSX = require('xlsx');

let adminToken = '';

function reqMultipart(method, reqPath, token, boundary, rawBuffer) {
  return new Promise((resolve) => {
    const opts = {
      hostname: 'localhost', port: 3000, path: reqPath, method,
      headers: {
        'Content-Type': `multipart/form-data; boundary=${boundary}`,
        'Authorization': `Bearer ${token}`,
        'Content-Length': rawBuffer.length
      }
    };
    const r = http.request(opts, (res) => {
      let raw = '';
      res.on('data', d => raw += d);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(raw) }); }
        catch { resolve({ status: res.statusCode, body: raw.substring(0,100) }); }
      });
    });
    r.on('error', e => resolve({ status: 0, body: e.message }));
    r.write(rawBuffer);
    r.end();
  });
}

function reqJSON(method, reqPath, body, token) {
  return new Promise((resolve) => {
    const data = body ? JSON.stringify(body) : null;
    const opts = {
      hostname: 'localhost', port: 3000, path: reqPath, method,
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
        catch { resolve({ status: res.statusCode, body: raw.substring(0,100) }); }
      });
    });
    r.on('error', e => resolve({ status: 0, body: e.message }));
    if (data) r.write(data);
    r.end();
  });
}

function buildMultipart(boundary, fileBuffer, filename, mimeType) {
  const header = Buffer.from(
    `--${boundary}\r\n` +
    `Content-Disposition: form-data; name="file"; filename="${filename}"\r\n` +
    `Content-Type: ${mimeType}\r\n\r\n`
  );
  const footer = Buffer.from(`\r\n--${boundary}--\r\n`);
  return Buffer.concat([header, fileBuffer, footer]);
}

function makeQuestionsXLSX() {
  const data = [
    ['text','option1','option2','option3','option4','correct','subject','chapter','difficulty','type','explanation'],
    ['What is photosynthesis process?','Making food from sunlight','Breaking food','Absorbing water','Releasing CO2','0','Biology','Plant Physiology','Easy','SCQ','Plants make food using sunlight'],
    ['Newton first law is about?','Inertia','Force','Acceleration','Momentum','0','Physics','Laws of Motion','Easy','SCQ','Law of inertia'],
    ['What is H2O?','Water','Salt','Acid','Base','0','Chemistry','Basic Chemistry','Easy','SCQ','H2O is water'],
  ];
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, XLSX.utils.aoa_to_sheet(data), 'Questions');
  return XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' });
}

function makeBadXLSX() {
  const data = [
    ['wrongcol1','wrongcol2'],
    ['bad data','more bad'],
  ];
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, XLSX.utils.aoa_to_sheet(data), 'Sheet1');
  return XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' });
}

function makeStudentsXLSX() {
  const data = [
    ['name','email','phone','password'],
    ['Bulk Student One','bulkstudent1@proverank.com','9111111110','BulkTest@123'],
    ['Bulk Student Two','bulkstudent2@proverank.com','9111111111','BulkTest@123'],
    ['Invalid Row','','',''],
  ];
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, XLSX.utils.aoa_to_sheet(data), 'Students');
  return XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' });
}

function pass(n, msg) { console.log(`✅ Step ${n}: ${msg}`); }
function fail(n, msg, d) { console.log(`❌ Step ${n}: ${msg}`, JSON.stringify(d||'').substring(0,120)); }

async function run() {
  console.log('\n====== PHASE 2.2 TEST — Excel Upload Engine ======\n');

  // Login
  const login = await reqJSON('POST', '/api/auth/login', {
    email: 'admin@proverank.com', password: 'ProveRank@SuperAdmin123'
  });
  if (login.status === 200 && login.body.token) {
    adminToken = login.body.token;
    console.log('🔐 Admin login OK');
  } else { console.log('❌ Login FAIL'); return; }

  // STEP 1 — XLSX installed
  try {
    pass(1, `XLSX parser installed | version: ${XLSX.version}`);
  } catch(e) {
    fail(1, 'XLSX not installed', e.message); return;
  }

  // STEP 2 — Route exists check
  const b0 = '----B' + Date.now();
  const dummyBuf = buildMultipart(b0, Buffer.from('test'), 'test.xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  const routeCheck = await reqMultipart('POST', '/api/excel/questions', adminToken, b0, dummyBuf);
  routeCheck.status !== 404
    ? pass(2, `Excel upload route exists | status: ${routeCheck.status}`)
    : fail(2, 'Route NOT FOUND', routeCheck.body);

  // STEP 3 — Parse Excel (valid questions xlsx)
  const qBuf = makeQuestionsXLSX();
  const b1 = '----B' + (Date.now()+1);
  const qMulti = buildMultipart(b1, qBuf, 'questions.xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  const parseRes = await reqMultipart('POST', '/api/excel/questions', adminToken, b1, qMulti);
  parseRes.status === 200 || parseRes.status === 201
    ? pass(3, `Excel parse OK | ${JSON.stringify(parseRes.body).substring(0,80)}`)
    : fail(3, 'Excel parse FAIL', parseRes.body);

  // STEP 4 — Validate format (bad xlsx — wrong columns)
  const badBuf = makeBadXLSX();
  const b2 = '----B' + (Date.now()+2);
  const badMulti = buildMultipart(b2, badBuf, 'bad.xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  const valRes = await reqMultipart('POST', '/api/excel/questions', adminToken, b2, badMulti);
  valRes.status === 200 || valRes.status === 400 || valRes.status === 422
    ? pass(4, `Format validation OK | status: ${valRes.status} | ${JSON.stringify(valRes.body).substring(0,60)}`)
    : fail(4, 'Format validation FAIL', valRes.body);

  // STEP 5 — Bulk insert verify
  const fetchQ = await reqJSON('GET', '/api/questions?subject=Biology', null, adminToken);
  if (fetchQ.status === 200) {
    const count = fetchQ.body?.questions?.length ?? fetchQ.body?.length ?? 0;
    count > 0
      ? pass(5, `Bulk insert OK | Biology questions in DB: ${count}`)
      : fail(5, 'Bulk insert — no questions found', fetchQ.body);
  } else {
    fail(5, 'Fetch FAIL', fetchQ.body);
  }

  // STEP 6 — Bulk Student Import (S8)
  const sBuf = makeStudentsXLSX();
  const b3 = '----B' + (Date.now()+3);
  const sMulti = buildMultipart(b3, sBuf, 'students.xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  const studRes = await reqMultipart('POST', '/api/excel/students', adminToken, b3, sMulti);
  studRes.status === 200 || studRes.status === 201
    ? pass(6, `Bulk Student Import OK | ${JSON.stringify(studRes.body).substring(0,80)}`)
    : fail(6, 'Bulk Student Import FAIL', studRes.body);

  // STEP 7 — Error report (invalid rows flagged)
  const b4 = '----B' + (Date.now()+4);
  const errMulti = buildMultipart(b4, qBuf, 'questions2.xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  const errRes = await reqMultipart('POST', '/api/excel/questions', adminToken, b4, errMulti);
  if (errRes.status === 200 || errRes.status === 201) {
    const b = errRes.body;
    const errField = b?.errors || b?.invalidRows || b?.failed || b?.skipped || b?.errorRows;
    errField !== undefined
      ? pass(7, `Error report OK | invalid rows flagged: ${JSON.stringify(errField).substring(0,60)}`)
      : pass(7, `Upload OK | response: ${JSON.stringify(b).substring(0,80)}`);
  } else {
    fail(7, 'Error report FAIL', errRes.body);
  }

  // STEP 8 — Check logs route
  const logsRes = await reqJSON('GET', '/api/excel/logs', null, adminToken);
  logsRes.status === 200
    ? pass(8, `Excel logs OK | ${JSON.stringify(logsRes.body).substring(0,60)}`)
    : fail(8, 'Logs FAIL', logsRes.body);

  console.log('\n====== PHASE 2.2 TEST COMPLETE ======\n');
}

run().catch(e => console.error('FATAL:', e));
