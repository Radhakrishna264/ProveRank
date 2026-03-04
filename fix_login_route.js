const fs = require('fs');
const path = '/home/user/workspace/src/routes/auth.js';
let code = fs.readFileSync(path, 'utf8');

// Find and fix the login section - replace password check
const oldCheck = `const match = await bcrypt.compare(password, user.password);
    if (!match) return res.status(400).json({ message: 'Invalid credentials' });`;
const newCheck = `let match = false;
    try { match = await bcrypt.compare(password, user.password); } catch(e) { console.log('bcrypt error:', e.message); }
    console.log('LOGIN DEBUG - email:', email, 'match:', match, 'hashLen:', user.password?.length);
    if (!match) return res.status(400).json({ message: 'Invalid credentials' });`;

if (code.includes('bcrypt.compare(password, user.password)')) {
  console.log('✅ Found bcrypt line');
} else {
  console.log('❌ Not found - showing relevant lines:');
  code.split('\n').forEach((l,i) => { if(l.includes('match') || l.includes('bcrypt') || l.includes('compare')) console.log(i+1, l); });
}
