const fs = require('fs');
const WS = process.env.HOME + '/workspace';

let test = fs.readFileSync(WS + '/test_phase_4_2.js', 'utf8');

// startRes.data.attemptId wali galat line remove karo
test = test.replace(
  /\s*attemptId = startRes\.data\.attemptId;\s*\n\s*console\.log\("Updated attemptId:"[^\n]*\n/,
  '\n'
);

// Sahi jagah fix karo - jahan startRes actually defined hai
// "Attempt created via API" se pehle wali try block mein
test = test.replace(
  /const startRes = await axios\.post[^;]+;(\s*)(.*?Attempt created via API[^\n]*\n)/s,
  (match, space, logLine) => {
    return match.replace(
      logLine,
      logLine + `    attemptId = startRes.data.attemptId || attemptId;\n`
    );
  }
);

fs.writeFileSync(WS + '/test_phase_4_2.js', test);

// Verify lines 80-100
console.log('=== Lines 80-105 ===');
test.split('\n').slice(79, 105).forEach((l,i) => console.log((80+i)+': '+l));
