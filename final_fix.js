const fs = require('fs');

// Correct path
const authPath = process.env.HOME + '/workspace/src/routes/auth.js';
let code = fs.readFileSync(authPath, 'utf8');

// Show lines around bcrypt
const lines = code.split('\n');
lines.forEach((l,i) => {
  if(l.includes('match') || l.includes('bcrypt') || l.includes('compare') || l.includes('verified') || l.includes('Invalid')) {
    console.log(i+1 + ': ' + l.trim());
  }
});

// Remove old debug log if exists
code = code.replace(/console\.log\('MATCH RESULT:'.*\n/g, '');
code = code.replace(/console\.log\("MATCH RESULT:".*\n/g, '');
code = code.replace(/console\.log\("LOGIN DEBUG.*\n/g, '');
code = code.replace(/let match = false;[\s\S]*?console\.log\('LOGIN.*?\n/g, '');

// Fix: replace bcrypt compare block with robust version
code = code.replace(
  /const match = await bcrypt\.compare\(password, user\.password\);/,
  `const plainPwd = String(password).trim();
    const hashPwd = String(user.password).trim();
    const match = await bcrypt.compare(plainPwd, hashPwd);
    console.log('🔐 LOGIN:', email, '| match:', match, '| pwdLen:', plainPwd.length, '| hashLen:', hashPwd.length);`
);

fs.writeFileSync(authPath, code);
console.log('\n✅ auth.js patched! Now restart server.');
