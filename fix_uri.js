const fs = require('fs');
const WS = process.env.HOME + '/workspace';

// index.js mein MONGODB_URI → MONGO_URI fix
let idx = fs.readFileSync(WS + '/src/index.js', 'utf8');
idx = idx.replace(/process\.env\.MONGODB_URI/g, 'process.env.MONGO_URI');
fs.writeFileSync(WS + '/src/index.js', idx);
console.log('FIX DONE: MONGODB_URI → MONGO_URI in index.js ✅');

// db.js bhi check karo
let db = fs.readFileSync(WS + '/src/config/db.js', 'utf8');
db = db.replace(/process\.env\.MONGODB_URI/g, 'process.env.MONGO_URI');
fs.writeFileSync(WS + '/src/config/db.js', db);
console.log('FIX DONE: MONGODB_URI → MONGO_URI in db.js ✅');

// Verify
console.log('\nVerify index.js:', require('fs').readFileSync(WS+'/src/index.js','utf8').includes('MONGODB_URI') ? '❌ Still wrong' : '✅ Fixed');
console.log('Verify db.js:', require('fs').readFileSync(WS+'/src/config/db.js','utf8').includes('MONGODB_URI') ? '❌ Still wrong' : '✅ Fixed');
