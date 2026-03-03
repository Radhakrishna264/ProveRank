const fs = require('fs');
const path = require('path');
const filePath = path.join(__dirname, 'src/models/Exam.js');
let content = fs.readFileSync(filePath, 'utf8');

// Remove bad injection and re-add properly
// First remove the broken part if exists
content = content.replace(/\s*whitelistEnabled:\s*\{[^}]+\},?\s*whitelistedStudents:[^,]+,?\s*whitelistedGroups:[^,\]]+\],?/g, '');
content = content.replace(/\s*maxAttempts:\s*\{[^}]+\},?\s*reattemptCount:[^}]+\},?/g, '');

// Now find a safe injection point - before }, { timestamps
const safePoint = content.lastIndexOf('}, {');
if (safePoint === -1) {
  console.log('❌ Safe injection point nahi mila');
  console.log('Last 200 chars:', content.slice(-200));
  process.exit(1);
}

const newFields = `,
  whitelistEnabled:    { type: Boolean, default: false },
  whitelistedStudents: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  whitelistedGroups:   [{ type: String }],
  maxAttempts:         { type: Number, default: 1 },
  reattemptCount:      { type: String, enum: ['best','last'], default: 'last' }`;

content = content.slice(0, safePoint) + newFields + '\n' + content.slice(safePoint);

fs.writeFileSync(filePath, content);
console.log('✅ Exam.js fixed!');

// Verify syntax
try {
  require(filePath);
  console.log('✅ Syntax OK!');
} catch(e) {
  console.log('❌ Still error:', e.message);
}
