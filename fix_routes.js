const fs = require('fs');
const p = './src/index.js';
let c = fs.readFileSync(p, 'utf8');

// Pehle dekho kya hai
const examLines = c.split('\n').filter(l => l.includes('exam') && (l.includes('require') || l.includes('app.use')));
console.log('Current exam routes:');
examLines.forEach((l,i) => console.log(i+':', l.trim()));

// exam_patch already hai?
console.log('\nexam_patch in file:', c.includes('exam_patch'));
