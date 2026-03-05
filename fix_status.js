const fs = require('fs');
const WS = process.env.HOME + '/workspace';

// exam.js mein start-attempt status check
const exam = fs.readFileSync(WS + '/src/routes/exam.js', 'utf8');
console.log('=== status line in start-attempt ===');
exam.split('\n').forEach((l,i) => {
  if(l.includes('status') && i > 60 && i < 90) console.log((i+1)+': '+l.trim());
});

// Fix: status explicitly 'active' set karo
let fixed = exam.replace(
  /status\s*:\s*['"]waiting['"]/g,
  "status: 'active'"
);

// Agar status hi nahi set ho raha new Attempt mein
if(!exam.includes("status: 'active'") && !exam.includes('status:"active"')) {
  fixed = fixed.replace(
    'ipAddress:',
    "status: 'active',\n      ipAddress:"
  );
  console.log('FIX: status active added to new Attempt');
}

fs.writeFileSync(WS + '/src/routes/exam.js', fixed);

// DB mein bhi current attempt active karo
const mongoose = require(WS + '/node_modules/mongoose');
const dotenv = require(WS + '/node_modules/dotenv');
dotenv.config({ path: WS + '/.env' });

mongoose.connect(process.env.MONGO_URI).then(async () => {
  const db = mongoose.connection.db;
  const r = await db.collection('attempts').updateMany(
    { status: { $in: ['waiting', 'instructions'] }},
    { $set: { status: 'active', startedAt: new Date() }}
  );
  console.log('DB attempts → active:', r.modifiedCount, '✅');
  
  const all = await db.collection('attempts').find({}).toArray();
  all.forEach(a => console.log('ID:', a._id.toString(), '| status:', a.status));
  
  await mongoose.disconnect();
}).catch(e => console.log('DB Error:', e.message));
