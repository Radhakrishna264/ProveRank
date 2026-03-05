const WS = process.env.HOME + '/workspace';
const fs = require('fs');

// 1. Attempt.js schema check
const schema = fs.readFileSync(WS + '/src/models/Attempt.js', 'utf8');
console.log('=== Attempt schema fields ===');
schema.split('\n').forEach((l,i) => {
  if(l.includes('start') || l.includes('Start') || l.includes('time') || l.includes('Time'))
    console.log((i+1)+': '+l.trim());
});

// 2. exam.js mein startTime → startedAt fix
let exam = fs.readFileSync(WS + '/src/routes/exam.js', 'utf8');
if(exam.includes('startTime:')) {
  exam = exam.replace(/startTime\s*:/g, 'startedAt:');
  fs.writeFileSync(WS + '/src/routes/exam.js', exam);
  console.log('\nFIX: startTime → startedAt in exam.js ✅');
} else {
  console.log('\nstartTime not found - checking other issue');
  // start-attempt handler show karo
  exam.split('\n').forEach((l,i) => {
    if(i >= 64 && i <= 84) console.log((i+1)+': '+l);
  });
}
