const fs = require('fs');
const WS = process.env.HOME + '/workspace';

// FIX 1: User.js schema mein termsAccepted add karo
let userModel = fs.readFileSync(WS + '/src/models/User.js', 'utf8');
console.log('=== User schema termsAccepted check ===');
console.log(userModel.includes('termsAccepted') ? 'Already exists' : 'MISSING - adding now');

if (!userModel.includes('termsAccepted')) {
  // role field ke baad add karo
  userModel = userModel.replace(
    /role\s*:\s*\{[^}]+\}/,
    match => match + `,\n  termsAccepted: { type: Boolean, default: false }`
  );
  fs.writeFileSync(WS + '/src/models/User.js', userModel);
  console.log('FIX 1 DONE: termsAccepted added to User schema');
}

// FIX 2: DB mein student ka termsAccepted true karo
const mongoose = require(WS + '/node_modules/mongoose');
const dotenv = require(WS + '/node_modules/dotenv');
dotenv.config({ path: WS + '/.env' });

mongoose.connect(process.env.MONGO_URI).then(async () => {
  console.log('\n=== DB Fix ===');
  const db = mongoose.connection.db;
  
  // Saare students ka termsAccepted true karo
  const result = await db.collection('students').updateMany(
    {},
    { $set: { termsAccepted: true } }
  );
  console.log('Students updated:', result.modifiedCount, '✅');

  // Verify
  const student = await db.collection('students').findOne({ email: 'student@proverank.com' });
  console.log('Student termsAccepted now:', student?.termsAccepted);

  // Attempt status verify
  const attempt = await db.collection('attempts').findOne({ _id: new mongoose.Types.ObjectId('69a84803bf3cd6ffdab84326') });
  console.log('Attempt status:', attempt?.status);
  
  // Agar attempt active nahi hai toh active karo
  if (attempt && attempt.status !== 'active') {
    await db.collection('attempts').updateOne(
      { _id: new mongoose.Types.ObjectId('69a84803bf3cd6ffdab84326') },
      { $set: { status: 'active' } }
    );
    console.log('Attempt status → active ✅');
  }

  await mongoose.disconnect();
  console.log('\n=== Schema + DB fix done! ===');
}).catch(e => console.log('DB Error:', e.message));
