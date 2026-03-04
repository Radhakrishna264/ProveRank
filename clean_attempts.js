const mongoose = require('mongoose');
const uri = process.env.MONGO_URI;
mongoose.connect(uri).then(async () => {
  const result = await mongoose.connection.collection('attempts').deleteMany({});
  console.log('Deleted attempts:', result.deletedCount);
  mongoose.disconnect();
});
