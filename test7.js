require('dotenv').config();
const mongoose = require('mongoose');
mongoose.connect(process.env.MONGO_URI);
mongoose.connection.once('open', async () => {
  const User = require('./src/models/User');
  console.log('Collection:', User.collection.name);
  mongoose.disconnect();
});
