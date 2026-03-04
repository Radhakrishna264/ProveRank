require('dotenv').config();
const mongoose = require('mongoose');
mongoose.connect(process.env.MONGO_URI);
mongoose.connection.once('open', async () => {
  console.log('SERVER DB:', mongoose.connection.db.databaseName);
  console.log('MONGO_URI:', process.env.MONGO_URI.substring(0,50));
  mongoose.disconnect();
});
