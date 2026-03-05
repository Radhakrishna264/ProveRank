const fs = require('fs');
const WS = process.env.HOME + '/workspace';

let test = fs.readFileSync(WS + '/test_phase_4_2.js', 'utf8');

// Check karo kahan attemptId set ho raha hai
console.log('=== attemptId assignment lines ===');
test.split('\n').forEach((l,i) => {
  if(l.includes('attemptId') && (l.includes('=') || l.includes('let') || l.includes('const')))
    console.log((i+1)+': '+l.trim());
});

// Fix: start-attempt response se attemptId lo
// Dhundo: "Using existing attempt" ya attempt create karne wali line
const hasAutoFetch = test.includes('attemptRes.data.attemptId') || 
                     test.includes('newAttempt.data.attemptId');
console.log('\nAuto-fetch attemptId from API:', hasAutoFetch ? '✅' : '❌ MISSING');

if(!hasAutoFetch) {
  // start-attempt call ke baad attemptId update karo
  test = test.replace(
    /console\.log\(`\${[GY]}Attempt created via API.*?\);\s*/,
    match => match + `  attemptId = startRes.data.attemptId;\n  console.log(\`Using new attemptId: \${attemptId}\`);\n  `
  );
  fs.writeFileSync(WS + '/test_phase_4_2.js', test);
  console.log('FIX: attemptId auto-update from API response ✅');
}
