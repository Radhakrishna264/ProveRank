const fs = require('fs');
const path = require('path');
const filePath = path.join(__dirname, 'src/models/Exam.js');
let content = fs.readFileSync(filePath, 'utf8');

const toAdd = [
  { check: 'whitelistEnabled', code: `  whitelistEnabled:     { type: Boolean, default: false },\n  whitelistedStudents:  [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],\n  whitelistedGroups:    [{ type: String }],` },
  { check: 'maxAttempts', code: `  maxAttempts:          { type: Number, default: 1 },\n  reattemptCount:       { type: String, enum: ['best','last'], default: 'last' },` },
];

toAdd.forEach(f => {
  if (content.includes(f.check)) {
    console.log(`⚠️  ${f.check} already exists`);
  } else {
    // Add before closing of schema
    content = content.replace(/(},\s*\{.*timestamps)/s, `  ${f.code}\n$1`);
    console.log(`✅ ${f.check} added to Exam model`);
  }
});

fs.writeFileSync(filePath, content);
console.log('✅ Exam.js updated!');
