const fs = require('fs');
const WS = process.env.HOME + '/workspace';
let exam = fs.readFileSync(WS + '/src/routes/exam.js', 'utf8');

console.log('User imported:', exam.includes("require('../models/User')") ? '✅' : '❌ MISSING');

if (!exam.includes("require('../models/User')")) {
  exam = exam.replace(
    "const Exam = require('../models/Exam');",
    "const Exam = require('../models/Exam');\nconst User = require('../models/User');"
  );
  fs.writeFileSync(WS + '/src/routes/exam.js', exam);
  console.log('FIX DONE: User model imported ✅');
}

// Verify all imports
console.log('\n=== exam.js top imports ===');
exam.split('\n').slice(0,10).forEach((l,i) => console.log((i+1)+': '+l));
