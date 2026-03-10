const fs = require('fs');
const path = require('path');
const filePath = path.join(__dirname, 'src/models/User.js');
let content = fs.readFileSync(filePath, 'utf8');

if (content.includes('frozen')) {
  console.log('⚠️  frozen field already exists');
} else {
  const inject = `
  // S72 — Admin freeze control
  frozen: { type: Boolean, default: false },
  // S37 — Admin permissions
  permissions: { type: Map, of: Boolean, default: {} },`;
  content = content.replace(/(\s*banned\s*:)/, `${inject}\n$1`);
  console.log('✅ frozen + permissions fields added');
}

fs.writeFileSync(filePath, content);
console.log('✅ User.js updated!');
