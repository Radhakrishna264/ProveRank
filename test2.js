require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const User = require('./src/models/User');
mongoose.connect(process.env.MONGO_URI).then(async()=>{
  const user = await User.findOne({email:'admin@proverank.com'});
  console.log('pwd:', user.password);
  const match = await bcrypt.compare('ProveRank@SuperAdmin123', user.password);
  console.log('MATCH:', match);
  mongoose.disconnect();
});
