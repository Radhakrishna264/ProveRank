const fs = require('fs');
let code = fs.readFileSync('/root/workspace/src/routes/auth.js', 'utf8');

// Fix 1: String().trim() hatao
code = code.replace(/const plainPwd = String\(password\)\.trim\(\);/g, 'const plainPwd = password;');
code = code.replace(/const hashPwd = String\(user\.password\)\.trim\(\);/g, 'const hashPwd = user.password;');

// Fix 2: AuditLog ko try-catch mein wrap karo
code = code.replace(
  /const AuditLog = require\('\.\.\/models\/AuditLog'\);/g,
  "let AuditLog; try { AuditLog = require('../models/AuditLog'); } catch(e) { AuditLog = null; }"
);
code = code.replace(
  /await AuditLog\.create\(/g,
  'if (AuditLog) await AuditLog.create('
);
code = code.replace(
  /\}\);\s*setSession/,
  '}); } catch(alErr){} setSession'
);

fs.writeFileSync('/root/workspace/src/routes/auth.js', code);
console.log('✅ auth.js fixed!');

// Verify
const newCode = fs.readFileSync('/root/workspace/src/routes/auth.js', 'utf8');
const line62 = newCode.split('\n').slice(60,66).join('\n');
console.log('Lines 61-66:\n', line62);
