require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./src/models/User');
mongoose.connect(process.env.MONGO_URI).then(async()=>{
  const user = await User.findOne({email:'admin@proverank.com'});
  console.log('user found:', !!user);
  if(user) console.log('role:', user.role, 'verified:', user.verified, 'pwdLen:', user.password.length);
  mongoose.disconnect();
});
