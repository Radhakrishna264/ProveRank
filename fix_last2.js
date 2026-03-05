const WS = process.env.HOME + '/workspace';
const fs = require('fs');
const mongoose = require(WS + '/node_modules/mongoose');
const dotenv = require(WS + '/node_modules/dotenv');
dotenv.config({ path: WS + '/.env' });

mongoose.connect(process.env.MONGO_URI).then(async () => {
  const db = mongoose.connection.db;

  // FIX 1: Attempt ka startedAt reset karo - fresh start time
  const now = new Date();
  const result = await db.collection('attempts').updateMany(
    { status: 'active' },
    { $set: { 
      startedAt: now,
      status: 'active'
    }}
  );
  console.log('FIX 1: startedAt reset to now ✅ | updated:', result.modifiedCount);

  // Verify
  const attempt = await db.collection('attempts').findOne({ status: 'active' });
  console.log('Attempt startedAt now:', attempt?.startedAt);

  await mongoose.disconnect();
}).catch(e => console.log('DB Error:', e.message));

// FIX 2: Navigation route 500 - handler check
const arJs = fs.readFileSync(WS + '/src/routes/attemptRoutes.js', 'utf8');
console.log('\n=== Navigation handler ===');
const lines = arJs.split('\n');
let inNav = false, bc = 0;
lines.forEach((l, i) => {
  if(l.includes('navigation') && l.includes('router.get')) inNav = true;
  if(inNav) {
    console.log((i+1)+': '+l);
    bc += (l.match(/\{/g)||[]).length - (l.match(/\}/g)||[]).length;
    if(bc < 0 && i > 0) inNav = false;
  }
});
