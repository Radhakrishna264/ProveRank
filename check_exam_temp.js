const mongoose = require('mongoose');
require('dotenv').config();
mongoose.connect(process.env.MONGO_URI).then(async () => {
  const Exam = require('./src/models/Exam');
  const exam = await Exam.findById('69a695892217ac6201221bfa');
  console.log('Exam:', exam ? exam.title : 'NULL');
  process.exit(0);
});
