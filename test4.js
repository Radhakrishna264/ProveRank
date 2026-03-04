require('dotenv').config();
const mongoose = require('mongoose');
mongoose.connect(process.env.MONGO_URI);
mongoose.connection.once('open', async () => {
  const User = require('./src/models/User');
  console.log('DB name:', mongoose.connection.db.databaseName);
  const u = await User.findOne({email:'admin@proverank.com'});
  console.log('Via Model:', u ? u.email : 'NOT FOUND');
  mongoose.disconnect();
});
