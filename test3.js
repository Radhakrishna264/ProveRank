require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const User = require('./src/models/User');
mongoose.connect(process.env.MONGO_URI).then(async()=>{
  const user = await User.findOne({email:'admin@proverank.com'});
  console.log('banned:', user.banned);
  console.log('verified:', user.verified);
  console.log('role:', user.role);
  const match = await bcrypt.compare('ProveRank@SuperAdmin123', user.password);
  console.log('match:', match);
  if(!user.verified && user.role !== 'superadmin' && user.role !== 'admin'){
    console.log('BLOCKED BY: verified check');
  } else if(user.banned){
    console.log('BLOCKED BY: banned check');
  } else if(!match){
    console.log('BLOCKED BY: password check');
  } else {
    console.log('ALL CHECKS PASS - should login!');
  }
  mongoose.disconnect();
});
