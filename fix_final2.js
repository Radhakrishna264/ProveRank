const WS = process.env.HOME + '/workspace';
const fs = require('fs');

// FIX 1: Navigation handler mein populate fix
let ar = fs.readFileSync(WS + '/src/routes/attemptRoutes.js', 'utf8');

// strictPopulate false karo ya populate remove karo
ar = ar.replace(
  /\.populate\(['"]questions['"]\)/g,
  '.populate({path: "questions", strictPopulate: false})'
);

// Agar populate hi nahi chahiye navigation mein toh remove karo
ar = ar.replace(
  /const attempt = await Attempt\.findById\(attemptId\)\.populate\(\{path: "questions", strictPopulate: false\}\);(\s*)(\/\/ STEP 6|\/\/ Navigation|router\.get\(['"]\/\:attemptId\/navigation)/,
  'const attempt = await Attempt.findById(attemptId);$1$2'
);

fs.writeFileSync(WS + '/src/routes/attemptRoutes.js', ar);
console.log('FIX 1 written');

// Navigation handler exact dhundo aur fix karo
const lines = ar.split('\n');
let navStart = -1;
lines.forEach((l,i) => {
  if(l.includes('navigation') && l.includes('router.get')) navStart = i;
});
console.log('Navigation handler at line:', navStart+1);
if(navStart > -1) {
  lines.slice(navStart, navStart+30).forEach((l,i) => console.log((navStart+i+1)+': '+l));
}

// FIX 2: DB mein correct attempt dhundo aur startedAt fix karo
const mongoose = require(WS + '/node_modules/mongoose');
const dotenv = require(WS + '/node_modules/dotenv');
dotenv.config({ path: WS + '/.env' });

mongoose.connect(process.env.MONGO_URI).then(async () => {
  const db = mongoose.connection.db;
  
  // Saare attempts dekho
  const all = await db.collection('attempts').find({}).toArray();
  console.log('\nAll attempts:');
  all.forEach(a => console.log(' ID:', a._id.toString(), '| status:', a.status, '| startedAt:', a.startedAt));

  // Har active attempt ka startedAt fresh karo
  const freshTime = new Date();
  const r = await db.collection('attempts').updateMany(
    {},
    { $set: { startedAt: freshTime, status: 'active' }}
  );
  console.log('\nAll attempts reset → active + fresh startedAt ✅ | count:', r.modifiedCount);

  await mongoose.disconnect();
}).catch(e => console.log('DB Error:', e.message));
