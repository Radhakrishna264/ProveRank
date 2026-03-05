const WS = process.env.HOME + '/workspace';
const mongoose = require(WS + '/node_modules/mongoose');
const dotenv = require(WS + '/node_modules/dotenv');
dotenv.config({ path: WS + '/.env' });

mongoose.connect(process.env.MONGO_URI).then(async () => {
  const db = mongoose.connection.db;
  
  // Saare attempts delete karo - fresh start
  const del = await db.collection('attempts').deleteMany({});
  console.log('Attempts deleted:', del.deletedCount, '✅');
  
  // termsAccepted true confirm
  await db.collection('students').updateMany({}, { $set: { termsAccepted: true }});
  console.log('termsAccepted → true ✅');
  
  // Verify
  const count = await db.collection('attempts').countDocuments();
  console.log('Attempts remaining:', count);
  
  await mongoose.disconnect();
  console.log('DB clean! Test chalao ab.');
}).catch(e => console.log('Error:', e.message));
