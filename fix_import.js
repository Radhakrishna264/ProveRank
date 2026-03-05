const fs = require('fs');
const WS = process.env.HOME + '/workspace';

let exam = fs.readFileSync(WS + '/src/routes/exam.js', 'utf8');

// Check
console.log('Attempt imported:', exam.includes("require('../models/Attempt')") ? '✅' : '❌ MISSING');

// Fix - Exam require ke baad Attempt add karo
if (!exam.includes("require('../models/Attempt')")) {
  exam = exam.replace(
    "const Exam = require('../models/Exam');",
    "const Exam = require('../models/Exam');\nconst Attempt = require('../models/Attempt');"
  );
  fs.writeFileSync(WS + '/src/routes/exam.js', exam);
  console.log('FIX DONE: Attempt model imported ✅');
}
