const mongoose = require('mongoose');
const MONGO_URI = process.env.MONGO_URI;

async function main() {
  await mongoose.connect(MONGO_URI);
  const Attempt = mongoose.model('Attempt', new mongoose.Schema({}, { strict: false }), 'attempts');
  
  const latest = await Attempt.findOne().sort({ createdAt: -1 });
  if (!latest) {
    console.log('❌ Koi bhi attempt DB mein nahi hai!');
    process.exit(1);
  }
  
  await Attempt.updateOne({ _id: latest._id }, { $set: { status: 'active' } });
  console.log('✅ Attempt status → active set kiya!');
  console.log('AttemptId:', latest._id.toString());
  
  await mongoose.disconnect();
}
main().catch(e => { console.error(e.message); process.exit(1); });
