const fs = require('fs');
const WS = process.env.HOME + '/workspace';

let test = fs.readFileSync(WS + '/test_phase_4_2.js', 'utf8');
const lines = test.split('\n');

// Line 84: attemptId = hardcoded ke baad API response se lo
// Line 85: console.log Attempt created via API

lines.forEach((l, i) => {
  if(l.includes("console.log(`${G}Attempt created via API") || 
     l.includes('Attempt created via API')) {
    console.log('Found at line:', i+1, ':', l.trim());
  }
});

// Fix: line 85 ke baad attemptId update karo
test = test.replace(
  /attemptId = startRes\.data\.attemptId \|\| attemptId;/,
  'attemptId = startRes.data.attemptId || attemptId;'
);

// Agar woh line nahi hai toh add karo
if(!test.includes('startRes.data.attemptId')) {
  // "Attempt created via API" console.log ke baad
  test = test.replace(
    /console\.log\(`\$\{G\}Attempt created via API[^`]*`[^)]*\);/,
    match => match + '\n    attemptId = startRes.data.attemptId || attemptId;\n    console.log("Updated attemptId:", attemptId);'
  );
  console.log('FIX DONE ✅');
}

fs.writeFileSync(WS + '/test_phase_4_2.js', test);

// Verify
const updated = fs.readFileSync(WS + '/test_phase_4_2.js', 'utf8');
console.log('\nVerify lines 83-90:');
updated.split('\n').slice(82, 92).forEach((l,i) => console.log((83+i)+': '+l));
