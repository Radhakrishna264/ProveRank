const fs = require('fs');
const path = require('path');
const filePath = path.join(__dirname, 'src/models/Question.js');
let content = fs.readFileSync(filePath, 'utf8');

const fields = [
  { check: 'isPYQ', inject: `  isPYQ:          { type: Boolean, default: false },\n  pyqYear:        { type: Number, default: null },` },
  { check: 'approvalStatus', inject: `  approvalStatus: { type: String, enum: ['pending','approved','rejected'], default: 'approved' },\n  approvedBy:     { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },\n  approvedAt:     { type: Date, default: null },\n  rejectionReason:{ type: String, default: null },` },
  { check: 'whitelistEnabled', inject: null }, // exam model mein
];

fields.forEach(f => {
  if (!f.inject) return;
  if (content.includes(f.check)) {
    console.log(`⚠️  ${f.check} already exists`);
  } else {
    content = content.replace(/(createdBy\s*:)/, `${f.inject}\n  $1`);
    console.log(`✅ ${f.check} field added`);
  }
});

fs.writeFileSync(filePath, content);
console.log('✅ Question.js updated!');
