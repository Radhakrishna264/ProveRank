require('dotenv').config();
const mongoose = require('mongoose');
mongoose.connect(process.env.MONGO_URI);
mongoose.connection.once('open', async () => {
  const User = require('./src/models/User');
  const email = 'admin@proverank.com';
  console.log('Searching for:', email);
  const user = await User.findOne({email: email});
  console.log('Result:', user ? 'FOUND: '+user.email : 'NULL');
  const user2 = await User.findOne({email: {$regex: /admin@proverank/i}});
  console.log('Regex search:', user2 ? 'FOUND: '+user2.email : 'NULL');
  mongoose.disconnect();
});
