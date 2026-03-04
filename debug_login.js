const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const User = require('./src/models/User');

mongoose.connect(process.env.MONGO_URI).then(async () => {
  const user = await User.findOne({email: 'admin@proverank.com'});
  console.log('=== DEBUG ===');
  console.log('Found:', !!user);
  console.log('password field:', user.password.substring(0, 20) + '...');
  console.log('password length:', user.password.length);
  
  const pass = 'ProveRank@SuperAdmin123';
  const r1 = await bcrypt.compare(pass, user.password);
  console.log('bcrypt.compare result:', r1);
  
  // Hash naya banao aur directly DB mein dalo
  const newHash = await bcrypt.hash(pass, 12);
  await User.collection.updateOne(
    {email: 'admin@proverank.com'},
    {$set: {password: newHash, verified: true, banned: false}}
  );
  
  // Ab verify karo
  const user2 = await User.findOne({email: 'admin@proverank.com'});
  const r2 = await bcrypt.compare(pass, user2.password);
  console.log('After fresh update - compare:', r2);
  console.log('New hash start:', user2.password.substring(0, 20));
  process.exit(0);
}).catch(e => { console.log('Error:', e.message); process.exit(1); });
