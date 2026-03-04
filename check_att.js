const mongoose = require('mongoose');
mongoose.connect(process.env.MONGO_URI).then(async () => {
  const atts = await mongoose.connection.collection('attempts').find({}).toArray();
  console.log('Total attempts:', atts.length, JSON.stringify(atts.map(a=>({studentId:a.studentId,examId:a.examId,status:a.status})), null, 2));
  mongoose.disconnect();
});
