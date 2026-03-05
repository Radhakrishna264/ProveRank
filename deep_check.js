const fs = require('fs');
const WS = process.env.HOME + '/workspace';

// 1. exam.js start-attempt exact route
console.log('=== exam.js start-attempt route ===');
const examJs = fs.readFileSync(WS + '/src/routes/exam.js', 'utf8');
const eLines = examJs.split('\n');
let inBlock = false, braceCount = 0;
eLines.forEach((l, i) => {
  if(l.includes('start-attempt')) { inBlock = true; braceCount = 0; }
  if(inBlock) {
    console.log((i+1)+': '+l);
    braceCount += (l.match(/\{/g)||[]).length - (l.match(/\}/g)||[]).length;
    if(braceCount < 0) { inBlock = false; }
  }
});

// 2. attemptRoutes - first 30 lines + save-answer handler
console.log('\n=== attemptRoutes.js top + save-answer ===');
const arJs = fs.readFileSync(WS + '/src/routes/attemptRoutes.js', 'utf8');
const arLines = arJs.split('\n');
// Top 10
arLines.slice(0,10).forEach((l,i) => console.log((i+1)+': '+l));
// save-answer block
let inSave = false, bc2 = 0;
arLines.forEach((l,i) => {
  if(l.includes('save-answer')) { inSave = true; bc2 = 0; }
  if(inSave) {
    console.log((i+1)+': '+l);
    bc2 += (l.match(/\{/g)||[]).length - (l.match(/\}/g)||[]).length;
    if(bc2 < 0 && i > 0) { inSave = false; }
  }
});

// 3. test script mein kya URL hai
console.log('\n=== test_phase_4_2.js attempt URL lines ===');
const testJs = fs.readFileSync(WS + '/test_phase_4_2.js', 'utf8');
testJs.split('\n').forEach((l,i) => {
  if(l.includes('attempts') || l.includes('attemptId') || l.includes('start-attempt'))
    console.log((i+1)+': '+l.trim());
});

// 4. index.js EXACT mount lines with line numbers
console.log('\n=== index.js exact mount ===');
const idx = fs.readFileSync(WS + '/src/index.js', 'utf8');
idx.split('\n').forEach((l,i) => {
  if(l.includes('app.use')) console.log((i+1)+': '+l.trim());
});
