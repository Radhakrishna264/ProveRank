const fs = require('fs');
const path = require('path');

const filePath = path.join(process.env.HOME, 'workspace/src/routes/auth.js');
let code = fs.readFileSync(filePath, 'utf8');

// Find and replace the entire login POST handler's password check section
const oldBlock = `    if (!user.verified) return res.status(400).json({ message: 'Email not verified' });`;
const newBlock = `    if (!user.verified && user.role !== 'superadmin' && user.role !== 'admin') return res.status(400).json({ message: 'Email not verified' });`;

if (code.includes(oldBlock)) {
  code = code.replace(oldBlock, newBlock);
  fs.writeFileSync(filePath, code);
  console.log('✅ Patch applied! Admin/superadmin bypass kiya verified check');
} else {
  console.log('❌ Line nahi mili - manual check karo');
}
