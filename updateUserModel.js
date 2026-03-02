const fs = require('fs');
const path = require('path');
const filePath = path.join(__dirname, 'src/models/User.js');
let content = fs.readFileSync(filePath, 'utf8');

if (content.includes('twoFactorEnabled')) {
  console.log('⚠️  2FA fields already exist');
} else {
  const inject2FA = `
  twoFactorEnabled: { type: Boolean, default: false },
  twoFactorSecret: { type: String, default: null },
  twoFactorTempSecret: { type: String, default: null },`;
  content = content.replace(/(\s*banned\s*:)/, `${inject2FA}\n$1`);
  console.log('✅ 2FA fields added');
}

if (content.includes('customFields')) {
  console.log('⚠️  customFields already exists');
} else {
  const injectCustom = `
  customFields: { type: Map, of: String, default: {} },`;
  content = content.replace(/(\s*banned\s*:)/, `${injectCustom}\n$1`);
  console.log('✅ customFields added');
}

fs.writeFileSync(filePath, content);
console.log('✅ User.js updated!');
