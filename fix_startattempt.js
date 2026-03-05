const WS = process.env.HOME + '/workspace';
const fs = require('fs');

// exam.js mein debug lines remove karo (woh crash kar sakti hain)
let exam = fs.readFileSync(WS + '/src/routes/exam.js', 'utf8');

// Pehle wali debug lines remove karo
exam = exam.replace(/\s*console\.log\('DEBUG.*?\);/g, '');
exam = exam.replace(/\s*const testExam = await require\(.*?\);/g, '');
exam = exam.replace(/\s*const testById = await require\(.*?\);/g, '');

fs.writeFileSync(WS + '/src/routes/exam.js', exam);
console.log('Debug lines removed from exam.js ✅');

// attemptRoutes se bhi debug lines hatao
let ar = fs.readFileSync(WS + '/src/routes/attemptRoutes.js', 'utf8');
ar = ar.replace(/\s*console\.log\('DEBUG.*?\);/g, '');
ar = ar.replace(/\s*const anyAttempt = await Attempt\.findOne\(\{\}\);/g, '');
fs.writeFileSync(WS + '/src/routes/attemptRoutes.js', ar);
console.log('Debug lines removed from attemptRoutes.js ✅');

// exam.js start-attempt ka try-catch verify karo
const examLines = exam.split('\n');
let found = false;
examLines.forEach((l,i) => {
  if(l.includes('start-attempt')) { found = true; }
  if(found && i < examLines.findIndex((x,j) => x.includes('start-attempt') && j > 0) + 30) {
    // just show
  }
});

console.log('\nDone! Server restart karo.');
