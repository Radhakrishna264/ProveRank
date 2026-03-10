const fs = require('fs');

// FIX 1: auth.js mein 400 → 401 fix
const authPath = '/home/runner/workspace/src/routes/auth.js';
let auth = fs.readFileSync(authPath, 'utf8');

// Wrong password / invalid credentials → must return 401
auth = auth.replace(
  "if (!user) return res.status(400).json({ message: 'Invalid credentials' });",
  "if (!user) return res.status(401).json({ message: 'Invalid credentials' });"
);
auth = auth.replace(
  "if (!match) return res.status(400).json({ message: 'Invalid credentials' });",
  "if (!match) return res.status(401).json({ message: 'Invalid credentials' });"
);
// Also fix any other 400 that should be 401 for credentials
auth = auth.replace(
  /res\.status\(400\)\.json\(\{ message: ['"]Invalid credentials['"]/g,
  "res.status(401).json({ message: 'Invalid credentials'"
);

fs.writeFileSync(authPath, auth);
console.log('✅ Fix 1 Done: auth.js → 401 for wrong credentials');

// FIX 2: Test script update — correct admin route use karo
const testPath = '/home/runner/workspace/test_stage10_step05.js';
let test = fs.readFileSync(testPath, 'utf8');

// Replace wrong route with correct existing route
test = test.replace(
  /\/api\/admin\/manage\/students/g,
  '/api/admin/manage/admins'
);

fs.writeFileSync(testPath, test);
console.log('✅ Fix 2 Done: Test script → /api/admin/manage/admins (correct route)');
console.log('\n🚀 Ab server restart karo phir test chalaao!');
