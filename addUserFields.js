const fs = require('fs');
const userPath = './src/models/User.js';
let content = fs.readFileSync(userPath, 'utf8');

const fieldsToAdd = `
  // S72: Permission Control
  permissions: {
    canCreateExam: { type: Boolean, default: true },
    canAddQuestion: { type: Boolean, default: true },
    canViewStudents: { type: Boolean, default: true },
    canImportBulk: { type: Boolean, default: true },
    canDeleteExam: { type: Boolean, default: false },
    canExportData: { type: Boolean, default: true }
  },
  isFrozen: { type: Boolean, default: false },
`;

// Check already hai kya
if (content.includes('isFrozen')) {
  console.log('ℹ️  Fields already exist in User.js — skip');
} else {
  // role ke baad add karo
  content = content.replace(
    /role:\s*\{[^}]+\}/,
    match => match + ',\n' + fieldsToAdd
  );
  fs.writeFileSync(userPath, content);
  console.log('✅ User.js mein permissions + isFrozen fields added!');
}
