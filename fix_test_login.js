require('dotenv').config();
const fs = require('fs');
let content = fs.readFileSync('./test_phase_4_2.js', 'utf8');
content = content.replace(
  "email: 'student1@test.com', password: 'ProveRank@123'",
  "email: 'admin@proverank.com', password: 'ProveRank@SuperAdmin123'"
);
content = content.replace(
  "console.log('❌ Student login failed",
  "console.log('❌ Admin login failed"
);
fs.writeFileSync('./test_phase_4_2.js', content);
console.log('✅ Test script updated to use admin login!');
