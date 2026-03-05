const fs = require('fs');
const WS = process.env.HOME + '/workspace';

// 1. Server log mein attemptRoutes error check
console.log('=== Server log check ===');
try {
  const log = fs.readFileSync('/tmp/server.log', 'utf8');
  log.split('\n').forEach(l => {
    if(l.includes('attempt') || l.includes('Error') || l.includes('Cannot'))
      console.log(l);
  });
} catch(e) { console.log('No server log'); }

// 2. exam.js mein start-attempt exact definition
console.log('\n=== exam.js start-attempt ===');
const examJs = fs.readFileSync(WS + '/src/routes/exam.js', 'utf8');
examJs.split('\n').forEach((l,i) => {
  if(l.includes('start-attempt') || (i > 60 && i < 100))
    console.log((i+1)+': '+l);
});

// FIX 1: index.js mein attemptRoutes ko try-catch se BAHAR karo
console.log('\n=== FIX: attemptRoutes try-catch remove ===');
let idx = fs.readFileSync(WS + '/src/index.js', 'utf8');

// try-catch wali pattern replace karo
const badPattern = /try\s*\{\s*const attemptRoutes\s*=\s*require\(['"]\.\/routes\/attemptRoutes['"]\);\s*app\.use\(['"]\/api\/attempts['"]\s*,\s*attemptRoutes\);\s*\}\s*catch\s*\(e\)\s*\{\s*\}/;

if(badPattern.test(idx)) {
  idx = idx.replace(badPattern, 
    `const attemptRoutes = require('./routes/attemptRoutes');\napp.use('/api/attempts', attemptRoutes);`
  );
  fs.writeFileSync(WS + '/src/index.js', idx);
  console.log('FIX 1 DONE: attemptRoutes try-catch removed!');
} else {
  console.log('Pattern not matched - manual check needed');
  // Show the lines around attemptRoutes
  idx.split('\n').forEach((l,i) => {
    if(l.includes('attemptRoutes')) console.log((i+1)+': '+l);
  });
}

// FIX 2: attemptRoutes.js require karo aur test karo
console.log('\n=== attemptRoutes require test ===');
try {
  const ar = require(WS + '/src/routes/attemptRoutes');
  console.log('attemptRoutes loads OK:', typeof ar);
} catch(e) {
  console.log('attemptRoutes REQUIRE ERROR:', e.message);
  // Agar error hai toh woh batao
}

console.log('\n=== DONE - Server restart karo ===');
